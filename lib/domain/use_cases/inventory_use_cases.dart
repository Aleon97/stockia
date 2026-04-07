import 'package:stockia/domain/entities/inventory_movement_entity.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/domain/repositories/inventory_movement_repository.dart';
import 'package:stockia/domain/repositories/product_repository.dart';
import 'package:stockia/domain/repositories/stock_alert_repository.dart';

class RegisterMovementUseCase {
  final InventoryMovementRepository _movementRepository;
  final ProductRepository _productRepository;
  final StockAlertRepository _alertRepository;

  RegisterMovementUseCase(
    this._movementRepository,
    this._productRepository,
    this._alertRepository,
  );

  Future<void> call(InventoryMovementEntity movement) async {
    final product = await _productRepository.getProductById(movement.productId);
    if (product == null) {
      throw Exception('Producto no encontrado');
    }

    // Calcular nuevo stock
    final int newStock;
    switch (movement.type) {
      case MovementType.IN:
        newStock = product.stock + movement.quantity;
        break;
      case MovementType.OUT:
        if (product.stock < movement.quantity) {
          throw Exception(
            'Stock insuficiente. Stock actual: ${product.stock}, cantidad solicitada: ${movement.quantity}',
          );
        }
        newStock = product.stock - movement.quantity;
        break;
      case MovementType.ADJUSTMENT:
        newStock = movement.quantity;
        break;
    }

    // Registrar movimiento
    await _movementRepository.createMovement(movement);

    // Actualizar stock del producto
    await _productRepository.updateStock(movement.productId, newStock);

    // Verificar si se debe generar alerta de stock bajo
    if (newStock <= product.minimumStock) {
      final now = DateTime.now();
      final alert = StockAlertEntity(
        id: '',
        productId: product.id,
        productName: product.name,
        currentStock: newStock,
        minimumStock: product.minimumStock,
        isResolved: false,
        tenantId: movement.tenantId,
        createdAt: now,
        updatedAt: now,
      );
      await _alertRepository.createAlert(alert);
    }
  }
}

class GetMovementsUseCase {
  final InventoryMovementRepository _repository;

  GetMovementsUseCase(this._repository);

  Future<List<InventoryMovementEntity>> call(String tenantId) {
    return _repository.getMovements(tenantId);
  }
}

class WatchMovementsUseCase {
  final InventoryMovementRepository _repository;

  WatchMovementsUseCase(this._repository);

  Stream<List<InventoryMovementEntity>> call(String tenantId) {
    return _repository.watchMovements(tenantId);
  }
}
