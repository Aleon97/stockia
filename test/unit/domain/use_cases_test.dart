import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/domain/entities/user_entity.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'package:stockia/domain/use_cases/auth_use_cases.dart';
import 'package:stockia/domain/use_cases/product_use_cases.dart';
import 'package:stockia/domain/use_cases/inventory_use_cases.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

void main() {
  // ═══════════════════════════════════════════════════
  // Auth Use Cases
  // ═══════════════════════════════════════════════════
  group('SignInUseCase', () {
    late MockAuthRepository mockAuth;
    late SignInUseCase useCase;

    setUp(() {
      mockAuth = MockAuthRepository();
      useCase = SignInUseCase(mockAuth);
    });

    test('llama signIn con email y password correctos', () async {
      final user = await useCase(email: 'test@stockia.com', password: '123456');
      expect(mockAuth.signInCalled, true);
      expect(user.email, 'test@stockia.com');
    });

    test('propaga error cuando el repositorio falla', () async {
      mockAuth.shouldThrow = true;
      expect(
        () => useCase(email: 'a@b.com', password: '123456'),
        throwsException,
      );
    });
  });

  group('SignUpUseCase', () {
    late MockAuthRepository mockAuth;
    late SignUpUseCase useCase;

    setUp(() {
      mockAuth = MockAuthRepository();
      useCase = SignUpUseCase(mockAuth);
    });

    test('registra usuario con datos completos', () async {
      final user = await useCase(testSignUpData);
      expect(mockAuth.signUpCalled, true);
      expect(mockAuth.lastSignUpData?.email, 'new@stockia.com');
      expect(mockAuth.lastSignUpData?.companyName, 'Mi Empresa');
      expect(user.email, 'new@stockia.com');
    });

    test('propaga error cuando el repositorio falla', () async {
      mockAuth.shouldThrow = true;
      expect(() => useCase(testSignUpData), throwsException);
    });
  });

  group('SignInWithSocialUseCase', () {
    late MockAuthRepository mockAuth;
    late SignInWithSocialUseCase useCase;

    setUp(() {
      mockAuth = MockAuthRepository();
      useCase = SignInWithSocialUseCase(mockAuth);
    });

    test('login con Google funciona', () async {
      final user = await useCase(SocialAuthProvider.google);
      expect(mockAuth.socialLoginCalled, true);
      expect(mockAuth.lastSocialProvider, SocialAuthProvider.google);
      expect(user, isA<UserEntity>());
    });

    test('login con Microsoft funciona', () async {
      await useCase(SocialAuthProvider.microsoft);
      expect(mockAuth.lastSocialProvider, SocialAuthProvider.microsoft);
    });
  });

  group('SignOutUseCase', () {
    late MockAuthRepository mockAuth;
    late SignOutUseCase useCase;

    setUp(() {
      mockAuth = MockAuthRepository();
      useCase = SignOutUseCase(mockAuth);
    });

    test('cierra sesión correctamente', () async {
      await useCase();
      expect(mockAuth.signOutCalled, true);
    });
  });

  group('GetCurrentUserUseCase', () {
    late MockAuthRepository mockAuth;
    late GetCurrentUserUseCase useCase;

    setUp(() {
      mockAuth = MockAuthRepository();
      useCase = GetCurrentUserUseCase(mockAuth);
    });

    test('retorna null cuando no hay usuario', () async {
      final user = await useCase();
      expect(user, isNull);
    });

    test('retorna usuario cuando existe sesión', () async {
      mockAuth.setCurrentUser(testUser);
      final user = await useCase();
      expect(user, isNotNull);
      expect(user?.email, 'test@stockia.com');
    });
  });

  // ═══════════════════════════════════════════════════
  // Product Use Cases
  // ═══════════════════════════════════════════════════
  group('GetProductsUseCase', () {
    late MockProductRepository mockProducts;
    late GetProductsUseCase useCase;

    setUp(() {
      mockProducts = MockProductRepository();
      useCase = GetProductsUseCase(mockProducts);
    });

    test('retorna productos del tenant correcto', () async {
      mockProducts.setProducts([
        testProduct1,
        testProduct2,
        testProductOtherTenant,
      ]);
      final products = await useCase('tenant-1');
      expect(products.length, 2);
      expect(products.every((p) => p.tenantId == 'tenant-1'), true);
    });

    test('retorna lista vacía para tenant sin productos', () async {
      mockProducts.setProducts([testProduct1]);
      final products = await useCase('nonexistent-tenant');
      expect(products, isEmpty);
    });
  });

  group('CreateProductUseCase', () {
    late MockProductRepository mockProducts;
    late MockStockAlertRepository mockAlerts;
    late CreateProductUseCase useCase;

    setUp(() {
      mockProducts = MockProductRepository();
      mockAlerts = MockStockAlertRepository();
      useCase = CreateProductUseCase(mockProducts, mockAlerts);
    });

    test('crea producto correctamente', () async {
      await useCase(testProduct1);
      expect(mockProducts.createCalled, true);
    });
  });

  group('UpdateProductUseCase', () {
    late MockProductRepository mockProducts;
    late MockStockAlertRepository mockAlerts;
    late UpdateProductUseCase useCase;

    setUp(() {
      mockProducts = MockProductRepository();
      mockAlerts = MockStockAlertRepository();
      useCase = UpdateProductUseCase(mockProducts, mockAlerts);
    });

    test('actualiza producto correctamente', () async {
      mockProducts.setProducts([testProduct1]);
      final updated = testProduct1.copyWith(stock: 100);
      await useCase(updated);
      expect(mockProducts.updateCalled, true);
    });
  });

  group('DeleteProductUseCase', () {
    late MockProductRepository mockProducts;
    late MockStockAlertRepository mockAlerts;
    late DeleteProductUseCase useCase;

    setUp(() {
      mockProducts = MockProductRepository();
      mockAlerts = MockStockAlertRepository();
      useCase = DeleteProductUseCase(mockProducts, mockAlerts);
    });

    test('elimina producto correctamente', () async {
      mockProducts.setProducts([testProduct1]);
      await useCase('prod-1');
      expect(mockProducts.deleteCalled, true);
    });
  });

  group('GetLowStockProductsUseCase', () {
    late MockProductRepository mockProducts;
    late GetLowStockProductsUseCase useCase;

    setUp(() {
      mockProducts = MockProductRepository();
      useCase = GetLowStockProductsUseCase(mockProducts);
    });

    test('retorna solo productos con stock bajo', () async {
      mockProducts.setProducts([testProduct1, testProduct2]);
      final lowStock = await useCase('tenant-1');
      expect(lowStock.length, 1);
      expect(lowStock.first.name, 'Destornillador');
    });
  });

  // ═══════════════════════════════════════════════════
  // Inventory Use Cases
  // ═══════════════════════════════════════════════════
  group('RegisterMovementUseCase', () {
    late MockProductRepository mockProducts;
    late MockInventoryMovementRepository mockMovements;
    late MockStockAlertRepository mockAlerts;
    late RegisterMovementUseCase useCase;

    setUp(() {
      mockProducts = MockProductRepository();
      mockMovements = MockInventoryMovementRepository();
      mockAlerts = MockStockAlertRepository();
      useCase = RegisterMovementUseCase(
        mockMovements,
        mockProducts,
        mockAlerts,
      );
    });

    test('movimiento IN incrementa stock', () async {
      mockProducts.setProducts([testProduct1]); // stock: 50
      await useCase(testMovementIn); // +20

      expect(mockMovements.createCalled, true);
      final products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 70); // 50 + 20
    });

    test('movimiento OUT decrementa stock', () async {
      mockProducts.setProducts([testProduct1]); // stock: 50
      await useCase(testMovementOut); // -5

      final products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 45); // 50 - 5
    });

    test('movimiento ADJUSTMENT establece stock exacto', () async {
      mockProducts.setProducts([testProduct1]); // stock: 50
      await useCase(testMovementAdjustment); // = 100

      final products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 100);
    });

    test('movimiento OUT con stock insuficiente lanza excepción', () async {
      mockProducts.setProducts([testProduct2]); // stock: 5
      final bigOut = InventoryMovementEntity(
        id: 'mov-big',
        type: MovementType.OUT,
        quantity: 100,
        productId: 'prod-2',
        date: now,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );

      expect(() => useCase(bigOut), throwsException);
    });

    test('producto no encontrado lanza excepción', () async {
      final badMovement = InventoryMovementEntity(
        id: 'mov-bad',
        type: MovementType.IN,
        quantity: 10,
        productId: 'nonexistent',
        date: now,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );

      expect(() => useCase(badMovement), throwsException);
    });

    test('genera alerta cuando stock queda bajo mínimo', () async {
      // Producto con stock 50, minimumStock 10
      // Sacamos 45, queda 5 <= 10 → alerta
      mockProducts.setProducts([testProduct1]);
      final bigOut = InventoryMovementEntity(
        id: 'mov-alert',
        type: MovementType.OUT,
        quantity: 45,
        productId: 'prod-1',
        date: now,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );

      await useCase(bigOut);
      expect(mockAlerts.createCalled, true);
    });

    test('NO genera alerta cuando stock queda sobre mínimo', () async {
      mockProducts.setProducts([testProduct1]); // stock: 50, min: 10
      await useCase(testMovementOut); // -5, queda 45 > 10

      expect(mockAlerts.createCalled, false);
    });
  });

  group('GetMovementsUseCase', () {
    late MockInventoryMovementRepository mockMovements;
    late GetMovementsUseCase useCase;

    setUp(() {
      mockMovements = MockInventoryMovementRepository();
      useCase = GetMovementsUseCase(mockMovements);
    });

    test('retorna movimientos del tenant', () async {
      mockMovements.setMovements([testMovementIn, testMovementOut]);
      final movements = await useCase('tenant-1');
      expect(movements.length, 2);
    });
  });
}
