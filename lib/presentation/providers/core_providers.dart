import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/data/repositories/auth_repository_impl.dart';
import 'package:stockia/data/repositories/category_repository_impl.dart';
import 'package:stockia/data/repositories/inventory_movement_repository_impl.dart';
import 'package:stockia/data/repositories/product_repository_impl.dart';
import 'package:stockia/data/repositories/stock_alert_repository_impl.dart';
import 'package:stockia/domain/entities/user_entity.dart';
import 'package:stockia/domain/entities/tenant_entity.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'package:stockia/domain/repositories/category_repository.dart';
import 'package:stockia/domain/repositories/inventory_movement_repository.dart';
import 'package:stockia/domain/repositories/product_repository.dart';
import 'package:stockia/domain/repositories/stock_alert_repository.dart';

// ── Firebase instances ──
final firebaseAuthProvider = Provider<firebase_auth.FirebaseAuth>(
  (ref) => firebase_auth.FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

// ── Repositories ──
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(firestore: ref.watch(firestoreProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl(firestore: ref.watch(firestoreProvider));
});

final inventoryMovementRepositoryProvider =
    Provider<InventoryMovementRepository>((ref) {
      return InventoryMovementRepositoryImpl(
        firestore: ref.watch(firestoreProvider),
      );
    });

final stockAlertRepositoryProvider = Provider<StockAlertRepository>((ref) {
  return StockAlertRepositoryImpl(firestore: ref.watch(firestoreProvider));
});

// ── Auth state ──
final authStateProvider = StreamProvider<firebase_auth.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserEntityProvider = FutureProvider<UserEntity?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return null;
      return ref.read(authRepositoryProvider).getCurrentUserEntity();
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ── Tenant ID ──
final tenantIdProvider = Provider<String?>((ref) {
  final userAsync = ref.watch(currentUserEntityProvider);
  return userAsync.whenOrNull(data: (user) => user?.tenantId);
});

// ── Tenant Entity ──
final tenantEntityProvider = FutureProvider<TenantEntity?>((ref) async {
  final tenantId = ref.watch(tenantIdProvider);
  if (tenantId == null) return null;
  final firestore = ref.read(firestoreProvider);
  final doc = await firestore.collection('tenants').doc(tenantId).get();
  if (!doc.exists) return null;
  return TenantEntity.fromFirestore(doc);
});
