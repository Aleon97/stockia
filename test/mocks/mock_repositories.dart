import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:stockia/domain/entities/user_entity.dart';
import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/domain/entities/category_entity.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'package:stockia/domain/repositories/product_repository.dart';
import 'package:stockia/domain/repositories/category_repository.dart';
import 'package:stockia/domain/repositories/inventory_movement_repository.dart';
import 'package:stockia/domain/repositories/stock_alert_repository.dart';

// ── Mock Auth Repository ──
class MockAuthRepository implements AuthRepository {
  UserEntity? _currentUser;
  final _authController = StreamController<firebase_auth.User?>.broadcast();
  bool signInCalled = false;
  bool signUpCalled = false;
  bool signOutCalled = false;
  bool socialLoginCalled = false;
  SocialAuthProvider? lastSocialProvider;
  SignUpData? lastSignUpData;
  bool shouldThrow = false;
  String errorMessage = 'Mock error';

  void setCurrentUser(UserEntity? user) {
    _currentUser = user;
  }

  @override
  Stream<firebase_auth.User?> get authStateChanges => _authController.stream;

  @override
  firebase_auth.User? get currentUser => null;

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    signInCalled = true;
    if (shouldThrow) throw Exception(errorMessage);
    _currentUser = UserEntity(
      id: 'test-uid',
      email: email,
      tenantId: 'test-tenant',
      displayName: 'Test User',
    );
    return _currentUser!;
  }

  @override
  Future<UserEntity> signUp(SignUpData data) async {
    signUpCalled = true;
    lastSignUpData = data;
    if (shouldThrow) throw Exception(errorMessage);
    _currentUser = UserEntity(
      id: 'new-uid',
      email: data.email,
      tenantId: 'new-tenant',
      displayName: data.companyName,
    );
    return _currentUser!;
  }

  @override
  Future<UserEntity> signInWithSocial(SocialAuthProvider provider) async {
    socialLoginCalled = true;
    lastSocialProvider = provider;
    if (shouldThrow) throw Exception(errorMessage);
    _currentUser = UserEntity(
      id: 'social-uid',
      email: 'social@test.com',
      tenantId: 'social-tenant',
      displayName: 'Social User',
    );
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _currentUser = null;
  }

  @override
  Future<UserEntity?> getCurrentUserEntity() async {
    return _currentUser;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<void> updateUserProfile({required String displayName}) async {
    if (shouldThrow) throw Exception(errorMessage);
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(displayName: displayName);
    }
  }

  @override
  Future<void> updateTenant({
    required String tenantId,
    required String name,
    required String nit,
    required String legalRepresentative,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
  }

  @override
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(email: newEmail);
    }
  }

  @override
  String? getAuthProvider() => _authProviderType;

  @override
  Future<bool> isEmailInUse(String email) async {
    return _emailsInUse.contains(email);
  }

  String _authProviderType = 'password';
  void setAuthProvider(String provider) => _authProviderType = provider;

  final Set<String> _emailsInUse = {};
  void addEmailInUse(String email) => _emailsInUse.add(email);

  void dispose() {
    _authController.close();
  }
}

// ── Mock Product Repository ──
class MockProductRepository implements ProductRepository {
  final List<ProductEntity> _products = [];
  final _productController = StreamController<List<ProductEntity>>.broadcast();
  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;
  bool shouldThrow = false;

  void setProducts(List<ProductEntity> products) {
    _products.clear();
    _products.addAll(products);
    _productController.add(_products);
  }

  @override
  Future<List<ProductEntity>> getProducts(String tenantId) async {
    return _products.where((p) => p.tenantId == tenantId).toList();
  }

  @override
  Stream<List<ProductEntity>> watchProducts(String tenantId) async* {
    yield _products.where((p) => p.tenantId == tenantId).toList();
    yield* _productController.stream.map(
      (list) => list.where((p) => p.tenantId == tenantId).toList(),
    );
  }

  @override
  Future<ProductEntity?> getProductById(String productId) async {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createProduct(ProductEntity product) async {
    createCalled = true;
    if (shouldThrow) throw Exception('Create product error');
    _products.add(product);
    _productController.add(_products);
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    updateCalled = true;
    if (shouldThrow) throw Exception('Update product error');
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _products[index] = product;
      _productController.add(_products);
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    deleteCalled = true;
    if (shouldThrow) throw Exception('Delete product error');
    _products.removeWhere((p) => p.id == productId);
    _productController.add(_products);
  }

  @override
  Future<void> updateStock(String productId, int newStock) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      _products[index] = _products[index].copyWith(stock: newStock);
      _productController.add(_products);
    }
  }

  @override
  Future<List<ProductEntity>> getLowStockProducts(String tenantId) async {
    return _products
        .where((p) => p.tenantId == tenantId && p.isLowStock)
        .toList();
  }

  void dispose() {
    _productController.close();
  }
}

// ── Mock Category Repository ──
class MockCategoryRepository implements CategoryRepository {
  final List<CategoryEntity> _categories = [];
  final _controller = StreamController<List<CategoryEntity>>.broadcast();

  void setCategories(List<CategoryEntity> categories) {
    _categories.clear();
    _categories.addAll(categories);
    _controller.add(_categories);
  }

  @override
  Future<List<CategoryEntity>> getCategories(String tenantId) async {
    return _categories.where((c) => c.tenantId == tenantId).toList();
  }

  @override
  Stream<List<CategoryEntity>> watchCategories(String tenantId) async* {
    yield _categories.where((c) => c.tenantId == tenantId).toList();
    yield* _controller.stream.map(
      (list) => list.where((c) => c.tenantId == tenantId).toList(),
    );
  }

  @override
  Future<void> createCategory(CategoryEntity category) async {
    _categories.add(category);
    _controller.add(_categories);
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    final i = _categories.indexWhere((c) => c.id == category.id);
    if (i >= 0) {
      _categories[i] = category;
      _controller.add(_categories);
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.id == categoryId);
    _controller.add(_categories);
  }

  void dispose() {
    _controller.close();
  }
}

// ── Mock Inventory Movement Repository ──
class MockInventoryMovementRepository implements InventoryMovementRepository {
  final List<InventoryMovementEntity> _movements = [];
  final _controller =
      StreamController<List<InventoryMovementEntity>>.broadcast();
  bool createCalled = false;

  void setMovements(List<InventoryMovementEntity> movements) {
    _movements.clear();
    _movements.addAll(movements);
    _controller.add(_movements);
  }

  @override
  Future<List<InventoryMovementEntity>> getMovements(String tenantId) async {
    return _movements.where((m) => m.tenantId == tenantId).toList();
  }

  @override
  Stream<List<InventoryMovementEntity>> watchMovements(String tenantId) async* {
    yield _movements.where((m) => m.tenantId == tenantId).toList();
    yield* _controller.stream.map(
      (list) => list.where((m) => m.tenantId == tenantId).toList(),
    );
  }

  @override
  Future<List<InventoryMovementEntity>> getMovementsByProduct(
    String tenantId,
    String productId,
  ) async {
    return _movements
        .where((m) => m.tenantId == tenantId && m.productId == productId)
        .toList();
  }

  @override
  Future<void> createMovement(InventoryMovementEntity movement) async {
    createCalled = true;
    _movements.add(movement);
    _controller.add(_movements);
  }

  void dispose() {
    _controller.close();
  }
}

// ── Mock Stock Alert Repository ──
class MockStockAlertRepository implements StockAlertRepository {
  final List<StockAlertEntity> _alerts = [];
  final _controller = StreamController<List<StockAlertEntity>>.broadcast();
  bool createCalled = false;
  bool resolveCalled = false;

  void setAlerts(List<StockAlertEntity> alerts) {
    _alerts.clear();
    _alerts.addAll(alerts);
    _controller.add(_alerts);
  }

  @override
  Future<List<StockAlertEntity>> getActiveAlerts(String tenantId) async {
    return _alerts
        .where((a) => a.tenantId == tenantId && !a.isResolved)
        .toList();
  }

  @override
  Stream<List<StockAlertEntity>> watchActiveAlerts(String tenantId) async* {
    yield _alerts
        .where((a) => a.tenantId == tenantId && !a.isResolved)
        .toList();
    yield* _controller.stream.map(
      (list) =>
          list.where((a) => a.tenantId == tenantId && !a.isResolved).toList(),
    );
  }

  @override
  Future<void> createAlert(StockAlertEntity alert) async {
    createCalled = true;
    _alerts.add(alert);
    _controller.add(_alerts);
  }

  @override
  Future<void> resolveAlert(String alertId) async {
    resolveCalled = true;
    // No-op for mock
  }

  @override
  Future<void> deleteAlertsByProductId(
    String productId,
    String tenantId,
  ) async {
    _alerts.removeWhere((a) => a.productId == productId);
    _controller.add(_alerts);
  }

  void dispose() {
    _controller.close();
  }
}
