import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/domain/entities/user_entity.dart';
import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/domain/entities/tenant_entity.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/presentation/providers/auth_providers.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/providers/product_providers.dart';
import 'package:stockia/presentation/providers/inventory_providers.dart';
import 'mock_repositories.dart';
import 'test_fixtures.dart';

/// Crea un ProviderScope con overrides de todos los providers de Firebase.
/// Esto permite renderizar cualquier pantalla sin Firebase real.
ProviderScope testProviderScope({
  required Widget child,
  MockAuthRepository? authRepo,
  MockProductRepository? productRepo,
  MockCategoryRepository? categoryRepo,
  MockInventoryMovementRepository? movementRepo,
  MockStockAlertRepository? alertRepo,
  UserEntity? currentUser,
  TenantEntity? tenant,
  String authProviderType = 'password',
  List<ProductEntity>? products,
  List<InventoryMovementEntity>? movements,
  List<StockAlertEntity>? alerts,
}) {
  final auth = authRepo ?? MockAuthRepository();
  final prods = productRepo ?? MockProductRepository();
  final cats = categoryRepo ?? MockCategoryRepository();
  final movs = movementRepo ?? MockInventoryMovementRepository();
  final alts = alertRepo ?? MockStockAlertRepository();

  if (products != null) prods.setProducts(products);
  if (movements != null) movs.setMovements(movements);
  if (alerts != null) alts.setAlerts(alerts);
  if (currentUser != null) auth.setCurrentUser(currentUser);

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      productRepositoryProvider.overrideWithValue(prods),
      categoryRepositoryProvider.overrideWithValue(cats),
      inventoryMovementRepositoryProvider.overrideWithValue(movs),
      stockAlertRepositoryProvider.overrideWithValue(alts),
      // Override auth state to avoid Firebase stream
      authStateProvider.overrideWith((ref) => Stream.value(null)),
      // Override currentUserEntity to avoid Firebase calls
      currentUserEntityProvider.overrideWith((ref) async => currentUser),
      // Override tenantId
      tenantIdProvider.overrideWithValue(currentUser?.tenantId),
      // Override tenant entity to avoid Firestore calls
      tenantEntityProvider.overrideWith((ref) async => tenant),
      // Override auth provider type
      authProviderTypeProvider.overrideWithValue(authProviderType),
      // Override product streams to use mock data
      productsStreamProvider.overrideWith((ref) {
        final tid = ref.watch(tenantIdProvider);
        if (tid == null) return const Stream.empty();
        return prods.watchProducts(tid);
      }),
      lowStockProductsProvider.overrideWith((ref) async {
        final tid = ref.watch(tenantIdProvider);
        if (tid == null) return [];
        return prods.getLowStockProducts(tid);
      }),
      movementsStreamProvider.overrideWith((ref) {
        final tid = ref.watch(tenantIdProvider);
        if (tid == null) return const Stream.empty();
        return movs.watchMovements(tid);
      }),
      stockAlertsStreamProvider.overrideWith((ref) {
        final tid = ref.watch(tenantIdProvider);
        if (tid == null) return const Stream.empty();
        return alts.watchActiveAlerts(tid);
      }),
    ],
    child: child,
  );
}
