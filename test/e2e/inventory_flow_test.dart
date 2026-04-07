import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/use_cases/product_use_cases.dart';
import 'package:stockia/domain/use_cases/inventory_use_cases.dart';
import '../mocks/mock_repositories.dart';
import '../mocks/test_fixtures.dart';

void main() {
  group('E2E – Flujo de inventario completo', () {
    late MockProductRepository mockProducts;
    late MockInventoryMovementRepository mockMovements;
    late MockStockAlertRepository mockAlerts;

    setUp(() {
      mockProducts = MockProductRepository();
      mockMovements = MockInventoryMovementRepository();
      mockAlerts = MockStockAlertRepository();
    });

    test(
      'Ciclo completo: crear producto → entrada → salida → alerta',
      () async {
        // 1. Crear producto
        final createUseCase = CreateProductUseCase(mockProducts, mockAlerts);
        await createUseCase(testProduct1);
        expect(mockProducts.createCalled, true);

        // 2. Verificar producto existe
        final getUseCase = GetProductsUseCase(mockProducts);
        var products = await getUseCase('tenant-1');
        expect(products.length, 1);
        expect(products.first.name, 'Martillo');
        expect(products.first.stock, 50);

        // 3. Registrar entrada de inventario (+20)
        final registerMovement = RegisterMovementUseCase(
          mockMovements,
          mockProducts,
          mockAlerts,
        );
        await registerMovement(testMovementIn);
        expect(mockMovements.createCalled, true);

        // 4. Verificar stock incrementado
        products = await getUseCase('tenant-1');
        expect(products.first.stock, 70); // 50 + 20

        // 5. Registrar salida grande (-65)
        final bigOut = InventoryMovementEntity(
          id: 'mov-big-out',
          type: MovementType.OUT,
          quantity: 65,
          productId: 'prod-1',
          date: now,
          tenantId: 'tenant-1',
          notes: 'Venta mayorista',
          createdAt: now,
          updatedAt: now,
        );
        await registerMovement(bigOut);

        // 6. Verificar stock decrementado
        products = await getUseCase('tenant-1');
        expect(products.first.stock, 5); // 70 - 65

        // 7. Verificar que se generó alerta (5 <= 10)
        expect(mockAlerts.createCalled, true);
      },
    );

    test('Multi-tenant: tenant A no ve productos de tenant B', () async {
      // Agregar productos de ambos tenants
      mockProducts.setProducts([testProduct1, testProductOtherTenant]);

      final getUseCase = GetProductsUseCase(mockProducts);

      // Tenant 1 solo ve sus productos
      final tenant1Products = await getUseCase('tenant-1');
      expect(tenant1Products.length, 1);
      expect(tenant1Products.first.tenantId, 'tenant-1');

      // Tenant 2 solo ve sus productos
      final tenant2Products = await getUseCase('tenant-2');
      expect(tenant2Products.length, 1);
      expect(tenant2Products.first.tenantId, 'tenant-2');
    });

    test('Actualizar producto mantiene integridad', () async {
      mockProducts.setProducts([testProduct1]);

      final updateUseCase = UpdateProductUseCase(mockProducts, mockAlerts);
      final updated = testProduct1.copyWith(
        name: 'Martillo Pro',
        salePrice: 45000,
        stock: 75,
      );
      await updateUseCase(updated);
      expect(mockProducts.updateCalled, true);

      final getUseCase = GetProductsUseCase(mockProducts);
      final products = await getUseCase('tenant-1');
      expect(products.first.name, 'Martillo Pro');
      expect(products.first.salePrice, 45000);
      expect(products.first.stock, 75);
    });

    test('Eliminar producto lo remueve del listado', () async {
      mockProducts.setProducts([testProduct1, testProduct2]);

      final deleteUseCase = DeleteProductUseCase(mockProducts, mockAlerts);
      await deleteUseCase('prod-1');
      expect(mockProducts.deleteCalled, true);

      final getUseCase = GetProductsUseCase(mockProducts);
      final products = await getUseCase('tenant-1');
      expect(products.length, 1);
      expect(products.first.name, 'Destornillador');
    });

    test('Low stock detecta productos bajo mínimo', () async {
      mockProducts.setProducts([testProduct1, testProduct2]);
      // testProduct1: stock 50, min 10 → OK
      // testProduct2: stock 5, min 10 → LOW

      final lowStockUseCase = GetLowStockProductsUseCase(mockProducts);
      final lowStock = await lowStockUseCase('tenant-1');

      expect(lowStock.length, 1);
      expect(lowStock.first.name, 'Destornillador');
      expect(lowStock.first.isLowStock, true);
    });

    test('Movimiento OUT con stock insuficiente es rechazado', () async {
      mockProducts.setProducts([testProduct2]); // stock: 5

      final registerMovement = RegisterMovementUseCase(
        mockMovements,
        mockProducts,
        mockAlerts,
      );

      final badMovement = InventoryMovementEntity(
        id: 'mov-fail',
        type: MovementType.OUT,
        quantity: 100,
        productId: 'prod-2',
        date: now,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );

      expect(
        () => registerMovement(badMovement),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Stock insuficiente'),
          ),
        ),
      );
    });

    test('Ajuste de inventario establece stock exacto', () async {
      mockProducts.setProducts([testProduct1]); // stock: 50

      final registerMovement = RegisterMovementUseCase(
        mockMovements,
        mockProducts,
        mockAlerts,
      );

      await registerMovement(testMovementAdjustment); // quantity: 100

      final products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 100); // Ajuste directo
    });

    test('Múltiples movimientos secuenciales mantienen consistencia', () async {
      mockProducts.setProducts([testProduct1]); // stock: 50

      final registerMovement = RegisterMovementUseCase(
        mockMovements,
        mockProducts,
        mockAlerts,
      );

      // +20 → 70
      await registerMovement(testMovementIn);
      var products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 70);

      // -5 → 65
      final out1 = InventoryMovementEntity(
        id: 'seq-out-1',
        type: MovementType.OUT,
        quantity: 5,
        productId: 'prod-1',
        date: now,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );
      await registerMovement(out1);
      products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 65);

      // +10 → 75
      final in1 = InventoryMovementEntity(
        id: 'seq-in-1',
        type: MovementType.IN,
        quantity: 10,
        productId: 'prod-1',
        date: now,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );
      await registerMovement(in1);
      products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 75);
    });
  });
}
