import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/repositories/inventory_movement_repository.dart';

class InventoryMovementRepositoryImpl implements InventoryMovementRepository {
  final FirebaseFirestore _firestore;

  InventoryMovementRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('inventory_movements');

  @override
  Future<List<InventoryMovementEntity>> getMovements(String tenantId) async {
    final snapshot = await _collection
        .where('tenantId', isEqualTo: tenantId)
        .get();

    final movements = snapshot.docs
        .map((doc) => InventoryMovementEntity.fromFirestore(doc))
        .toList();
    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements;
  }

  @override
  Stream<List<InventoryMovementEntity>> watchMovements(String tenantId) {
    return _collection.where('tenantId', isEqualTo: tenantId).snapshots().map((
      snapshot,
    ) {
      final movements = snapshot.docs
          .map((doc) => InventoryMovementEntity.fromFirestore(doc))
          .toList();
      movements.sort((a, b) => b.date.compareTo(a.date));
      return movements;
    });
  }

  @override
  Future<List<InventoryMovementEntity>> getMovementsByProduct(
    String tenantId,
    String productId,
  ) async {
    final snapshot = await _collection
        .where('tenantId', isEqualTo: tenantId)
        .get();

    final movements = snapshot.docs
        .map((doc) => InventoryMovementEntity.fromFirestore(doc))
        .where((m) => m.productId == productId)
        .toList();
    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements;
  }

  @override
  Future<void> createMovement(InventoryMovementEntity movement) async {
    await _collection.add(movement.toMap());
  }
}
