import 'package:stockia/domain/entities/inventory_movement_entity.dart';

abstract class InventoryMovementRepository {
  Future<List<InventoryMovementEntity>> getMovements(String tenantId);
  Stream<List<InventoryMovementEntity>> watchMovements(String tenantId);
  Future<List<InventoryMovementEntity>> getMovementsByProduct(
    String tenantId,
    String productId,
  );
  Future<void> createMovement(InventoryMovementEntity movement);
}
