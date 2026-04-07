import 'package:flutter_test/flutter_test.dart';
import 'package:stockia/domain/entities/category_entity.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'mock_repositories.dart';
import 'test_fixtures.dart';

/// Tests robustos para validar que TODOS los mocks funcionan correctamente.
/// Estos tests garantizan la integridad del sistema de mocking antes de
/// ejecutar tests de UI (smoke) o E2E.
void main() {
  // ═══════════════════════════════════════════════════════════
  // MockAuthRepository
  // ═══════════════════════════════════════════════════════════
  group('MockAuthRepository', () {
    late MockAuthRepository mockAuth;

    setUp(() {
      mockAuth = MockAuthRepository();
    });

    test('signIn retorna usuario y marca signInCalled', () async {
      final user = await mockAuth.signIn(email: 'a@b.com', password: '123');
      expect(mockAuth.signInCalled, true);
      expect(user.email, 'a@b.com');
      expect(user.tenantId, 'test-tenant');
    });

    test('signIn con shouldThrow lanza excepción', () async {
      mockAuth.shouldThrow = true;
      mockAuth.errorMessage = 'Login failed';
      expect(
        () => mockAuth.signIn(email: 'a@b.com', password: '123'),
        throwsA(isA<Exception>()),
      );
    });

    test('signUp retorna usuario y guarda SignUpData', () async {
      final user = await mockAuth.signUp(testSignUpData);
      expect(mockAuth.signUpCalled, true);
      expect(mockAuth.lastSignUpData?.email, 'new@stockia.com');
      expect(mockAuth.lastSignUpData?.companyName, 'Mi Empresa');
      expect(user.email, 'new@stockia.com');
    });

    test('signUp con shouldThrow lanza excepción', () async {
      mockAuth.shouldThrow = true;
      expect(() => mockAuth.signUp(testSignUpData), throwsException);
    });

    test('signInWithSocial Google funciona', () async {
      final user = await mockAuth.signInWithSocial(SocialAuthProvider.google);
      expect(mockAuth.socialLoginCalled, true);
      expect(mockAuth.lastSocialProvider, SocialAuthProvider.google);
      expect(user.email, 'social@test.com');
    });

    test('signInWithSocial Microsoft funciona', () async {
      await mockAuth.signInWithSocial(SocialAuthProvider.microsoft);
      expect(mockAuth.lastSocialProvider, SocialAuthProvider.microsoft);
    });

    test('signOut marca flag y limpia usuario', () async {
      mockAuth.setCurrentUser(testUser);
      await mockAuth.signOut();
      expect(mockAuth.signOutCalled, true);
      final user = await mockAuth.getCurrentUserEntity();
      expect(user, isNull);
    });

    test('getCurrentUserEntity retorna null sin usuario', () async {
      final user = await mockAuth.getCurrentUserEntity();
      expect(user, isNull);
    });

    test('getCurrentUserEntity retorna usuario configurado', () async {
      mockAuth.setCurrentUser(testUser);
      final user = await mockAuth.getCurrentUserEntity();
      expect(user, isNotNull);
      expect(user?.email, 'test@stockia.com');
    });

    test('authStateChanges emite stream', () {
      expect(mockAuth.authStateChanges, isA<Stream>());
    });

    test('currentUser retorna null (mock)', () {
      expect(mockAuth.currentUser, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // MockProductRepository
  // ═══════════════════════════════════════════════════════════
  group('MockProductRepository', () {
    late MockProductRepository mockProducts;

    setUp(() {
      mockProducts = MockProductRepository();
    });

    test('getProducts filtra por tenantId', () async {
      mockProducts.setProducts([testProduct1, testProductOtherTenant]);
      final products = await mockProducts.getProducts('tenant-1');
      expect(products.length, 1);
      expect(products.first.tenantId, 'tenant-1');
    });

    test('getProducts retorna vacío para tenant inexistente', () async {
      mockProducts.setProducts([testProduct1]);
      final products = await mockProducts.getProducts('nonexistent');
      expect(products, isEmpty);
    });

    test('watchProducts emite stream filtrado', () async {
      mockProducts.setProducts([testProduct1, testProductOtherTenant]);
      final products = await mockProducts.watchProducts('tenant-1').first;
      expect(products.length, 1);
    });

    test('getProductById retorna producto existente', () async {
      mockProducts.setProducts([testProduct1]);
      final product = await mockProducts.getProductById('prod-1');
      expect(product, isNotNull);
      expect(product?.name, 'Martillo');
    });

    test('getProductById retorna null si no existe', () async {
      mockProducts.setProducts([testProduct1]);
      final product = await mockProducts.getProductById('nonexistent');
      expect(product, isNull);
    });

    test('createProduct agrega al store interno', () async {
      await mockProducts.createProduct(testProduct1);
      expect(mockProducts.createCalled, true);
      final products = await mockProducts.getProducts('tenant-1');
      expect(products.length, 1);
    });

    test('createProduct con shouldThrow lanza excepción', () async {
      mockProducts.shouldThrow = true;
      expect(() => mockProducts.createProduct(testProduct1), throwsException);
    });

    test('updateProduct modifica producto existente', () async {
      mockProducts.setProducts([testProduct1]);
      final updated = testProduct1.copyWith(name: 'Martillo Pro');
      await mockProducts.updateProduct(updated);
      expect(mockProducts.updateCalled, true);
      final products = await mockProducts.getProducts('tenant-1');
      expect(products.first.name, 'Martillo Pro');
    });

    test('deleteProduct remueve del store', () async {
      mockProducts.setProducts([testProduct1, testProduct2]);
      await mockProducts.deleteProduct('prod-1');
      expect(mockProducts.deleteCalled, true);
      final products = await mockProducts.getProducts('tenant-1');
      expect(products.length, 1);
      expect(products.first.name, 'Destornillador');
    });

    test('updateStock actualiza stock directamente', () async {
      mockProducts.setProducts([testProduct1]); // stock: 50
      await mockProducts.updateStock('prod-1', 99);
      final products = await mockProducts.getProducts('tenant-1');
      expect(products.first.stock, 99);
    });

    test('getLowStockProducts retorna solo los correctos', () async {
      mockProducts.setProducts([testProduct1, testProduct2]);
      final lowStock = await mockProducts.getLowStockProducts('tenant-1');
      expect(lowStock.length, 1);
      expect(lowStock.first.name, 'Destornillador');
    });

    test('getLowStockProducts filtra por tenant', () async {
      mockProducts.setProducts([testProduct2, testProductOtherTenant]);
      final lowStock = await mockProducts.getLowStockProducts('tenant-1');
      expect(lowStock.length, 1);
      expect(lowStock.first.tenantId, 'tenant-1');
    });
  });

  // ═══════════════════════════════════════════════════════════
  // MockCategoryRepository
  // ═══════════════════════════════════════════════════════════
  group('MockCategoryRepository', () {
    late MockCategoryRepository mockCategories;

    setUp(() {
      mockCategories = MockCategoryRepository();
    });

    test('getCategories filtra por tenantId', () async {
      final cat2 = CategoryEntity(
        id: 'cat-2',
        name: 'Eléctricos',
        tenantId: 'tenant-2',
        createdAt: now,
        updatedAt: now,
      );
      mockCategories.setCategories([testCategory, cat2]);

      final categories = await mockCategories.getCategories('tenant-1');
      expect(categories.length, 1);
      expect(categories.first.name, 'Herramientas manuales');
    });

    test('createCategory agrega al store', () async {
      await mockCategories.createCategory(testCategory);
      final categories = await mockCategories.getCategories('tenant-1');
      expect(categories.length, 1);
    });

    test('updateCategory modifica categoría', () async {
      mockCategories.setCategories([testCategory]);
      final updated = CategoryEntity(
        id: 'cat-1',
        name: 'Herramientas actualizado',
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );
      await mockCategories.updateCategory(updated);
      final categories = await mockCategories.getCategories('tenant-1');
      expect(categories.first.name, 'Herramientas actualizado');
    });

    test('deleteCategory remueve del store', () async {
      mockCategories.setCategories([testCategory]);
      await mockCategories.deleteCategory('cat-1');
      final categories = await mockCategories.getCategories('tenant-1');
      expect(categories, isEmpty);
    });

    test('watchCategories emite stream', () async {
      mockCategories.setCategories([testCategory]);
      final categories = await mockCategories.watchCategories('tenant-1').first;
      expect(categories.length, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // MockInventoryMovementRepository
  // ═══════════════════════════════════════════════════════════
  group('MockInventoryMovementRepository', () {
    late MockInventoryMovementRepository mockMovements;

    setUp(() {
      mockMovements = MockInventoryMovementRepository();
    });

    test('getMovements filtra por tenant', () async {
      final otherMovement = InventoryMovementEntity(
        id: 'mov-other',
        type: MovementType.IN,
        quantity: 10,
        productId: 'prod-3',
        date: now,
        tenantId: 'tenant-2',
        createdAt: now,
        updatedAt: now,
      );
      mockMovements.setMovements([testMovementIn, otherMovement]);

      final movements = await mockMovements.getMovements('tenant-1');
      expect(movements.length, 1);
      expect(movements.first.tenantId, 'tenant-1');
    });

    test('getMovementsByProduct filtra por producto y tenant', () async {
      mockMovements.setMovements([testMovementIn, testMovementOut]);

      final movements = await mockMovements.getMovementsByProduct(
        'tenant-1',
        'prod-1',
      );
      expect(movements.length, 2);
    });

    test('createMovement agrega al store', () async {
      await mockMovements.createMovement(testMovementIn);
      expect(mockMovements.createCalled, true);
    });

    test('watchMovements emite stream filtrado', () async {
      mockMovements.setMovements([testMovementIn]);
      final movements = await mockMovements.watchMovements('tenant-1').first;
      expect(movements.length, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // MockStockAlertRepository
  // ═══════════════════════════════════════════════════════════
  group('MockStockAlertRepository', () {
    late MockStockAlertRepository mockAlerts;

    setUp(() {
      mockAlerts = MockStockAlertRepository();
    });

    test('getActiveAlerts filtra por tenant y no resueltas', () async {
      final resolvedAlert = StockAlertEntity(
        id: 'alert-resolved',
        productId: 'prod-1',
        productName: 'Martillo',
        currentStock: 5,
        minimumStock: 10,
        isResolved: true,
        tenantId: 'tenant-1',
        createdAt: now,
        updatedAt: now,
      );
      mockAlerts.setAlerts([testAlert, resolvedAlert]);

      final alerts = await mockAlerts.getActiveAlerts('tenant-1');
      expect(alerts.length, 1);
      expect(alerts.first.isResolved, false);
    });

    test('getActiveAlerts filtra por tenant', () async {
      final otherAlert = StockAlertEntity(
        id: 'alert-other',
        productId: 'prod-3',
        productName: 'Llave',
        currentStock: 1,
        minimumStock: 5,
        isResolved: false,
        tenantId: 'tenant-2',
        createdAt: now,
        updatedAt: now,
      );
      mockAlerts.setAlerts([testAlert, otherAlert]);

      final alerts = await mockAlerts.getActiveAlerts('tenant-1');
      expect(alerts.length, 1);
    });

    test('createAlert marca flag', () async {
      await mockAlerts.createAlert(testAlert);
      expect(mockAlerts.createCalled, true);
    });

    test('resolveAlert marca flag', () async {
      await mockAlerts.resolveAlert('alert-1');
      expect(mockAlerts.resolveCalled, true);
    });

    test('deleteAlertsByProductId elimina alertas del producto', () async {
      mockAlerts.setAlerts([testAlert]);
      await mockAlerts.deleteAlertsByProductId('prod-2', 'tenant-1');
      final alerts = await mockAlerts.getActiveAlerts('tenant-1');
      expect(alerts, isEmpty);
    });

    test('watchActiveAlerts emite stream filtrado', () async {
      mockAlerts.setAlerts([testAlert]);
      final alerts = await mockAlerts.watchActiveAlerts('tenant-1').first;
      expect(alerts.length, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Validación de integridad de test_fixtures
  // ═══════════════════════════════════════════════════════════
  group('Test Fixtures – Integridad', () {
    test('testUser tiene todos los campos', () {
      expect(testUser.id, isNotEmpty);
      expect(testUser.email, contains('@'));
      expect(testUser.tenantId, isNotEmpty);
      expect(testUser.displayName, isNotNull);
    });

    test('testUser2 es de otro tenant', () {
      expect(testUser2.tenantId, isNot(testUser.tenantId));
    });

    test('testProduct1 tiene stock OK', () {
      expect(testProduct1.isLowStock, false);
      expect(testProduct1.stock, greaterThan(testProduct1.minimumStock));
    });

    test('testProduct2 tiene stock bajo', () {
      expect(testProduct2.isLowStock, true);
      expect(testProduct2.stock, lessThanOrEqualTo(testProduct2.minimumStock));
    });

    test('testProductOtherTenant es de tenant-2', () {
      expect(testProductOtherTenant.tenantId, 'tenant-2');
    });

    test('testProduct1 y testProduct2 son del mismo tenant', () {
      expect(testProduct1.tenantId, testProduct2.tenantId);
    });

    test('testMovementIn es tipo IN', () {
      expect(testMovementIn.type, MovementType.IN);
      expect(testMovementIn.quantity, greaterThan(0));
    });

    test('testMovementOut es tipo OUT', () {
      expect(testMovementOut.type, MovementType.OUT);
      expect(testMovementOut.quantity, greaterThan(0));
    });

    test('testMovementAdjustment es tipo ADJUSTMENT', () {
      expect(testMovementAdjustment.type, MovementType.ADJUSTMENT);
    });

    test('testAlert es para producto con stock bajo', () {
      expect(testAlert.isResolved, false);
      expect(testAlert.currentStock, lessThan(testAlert.minimumStock));
    });

    test('testAlert corresponde a testProduct2', () {
      expect(testAlert.productId, testProduct2.id);
      expect(testAlert.productName, testProduct2.name);
    });

    test('testSignUpData tiene todos los campos', () {
      expect(testSignUpData.email, contains('@'));
      expect(testSignUpData.password.length, greaterThanOrEqualTo(6));
      expect(testSignUpData.companyName, isNotEmpty);
      expect(testSignUpData.nit, isNotEmpty);
      expect(testSignUpData.businessType, isNotEmpty);
      expect(testSignUpData.legalRepresentative, isNotEmpty);
    });

    test('Todos los movimientos y alertas pertenecen a tenant-1', () {
      expect(testMovementIn.tenantId, 'tenant-1');
      expect(testMovementOut.tenantId, 'tenant-1');
      expect(testMovementAdjustment.tenantId, 'tenant-1');
      expect(testAlert.tenantId, 'tenant-1');
    });

    test('testTenant tiene datos completos', () {
      expect(testTenant.name, isNotEmpty);
      expect(testTenant.nit, isNotEmpty);
      expect(testTenant.businessType, isNotEmpty);
      expect(testTenant.legalRepresentative, isNotEmpty);
    });

    test('Precios de testProduct1 son válidos', () {
      expect(testProduct1.costPrice, greaterThan(0));
      expect(testProduct1.salePrice, greaterThan(0));
      expect(testProduct1.salePrice, greaterThan(testProduct1.costPrice));
    });

    test('Precios de testProduct2 son válidos', () {
      expect(testProduct2.costPrice, greaterThan(0));
      expect(testProduct2.salePrice, greaterThan(testProduct2.costPrice));
    });
  });
}
