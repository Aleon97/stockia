import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/domain/entities/stock_alert_entity.dart';
import 'package:stockia/domain/repositories/product_repository.dart';
import 'package:stockia/domain/repositories/stock_alert_repository.dart';

class GetProductsUseCase {
  final ProductRepository _repository;

  GetProductsUseCase(this._repository);

  Future<List<ProductEntity>> call(String tenantId) {
    return _repository.getProducts(tenantId);
  }
}

class WatchProductsUseCase {
  final ProductRepository _repository;

  WatchProductsUseCase(this._repository);

  Stream<List<ProductEntity>> call(String tenantId) {
    return _repository.watchProducts(tenantId);
  }
}

class CreateProductUseCase {
  final ProductRepository _repository;
  final StockAlertRepository _alertRepository;

  CreateProductUseCase(this._repository, this._alertRepository);

  Future<void> call(ProductEntity product) async {
    await _repository.createProduct(product);

    if (product.isLowStock) {
      final now = DateTime.now();
      await _alertRepository.createAlert(
        StockAlertEntity(
          id: '',
          productId: product.id,
          productName: product.name,
          currentStock: product.stock,
          minimumStock: product.minimumStock,
          isResolved: false,
          tenantId: product.tenantId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}

class UpdateProductUseCase {
  final ProductRepository _repository;
  final StockAlertRepository _alertRepository;

  UpdateProductUseCase(this._repository, this._alertRepository);

  Future<void> call(ProductEntity product) async {
    await _repository.updateProduct(product);

    if (product.isLowStock) {
      final now = DateTime.now();
      await _alertRepository.createAlert(
        StockAlertEntity(
          id: '',
          productId: product.id,
          productName: product.name,
          currentStock: product.stock,
          minimumStock: product.minimumStock,
          isResolved: false,
          tenantId: product.tenantId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await _alertRepository.deleteAlertsByProductId(
        product.id,
        product.tenantId,
      );
    }
  }
}

class DeleteProductUseCase {
  final ProductRepository _repository;
  final StockAlertRepository _alertRepository;

  DeleteProductUseCase(this._repository, this._alertRepository);

  Future<void> call(String productId) async {
    final product = await _repository.getProductById(productId);
    if (product != null) {
      await _alertRepository.deleteAlertsByProductId(
        productId,
        product.tenantId,
      );
    }
    await _repository.deleteProduct(productId);
  }
}

class GetLowStockProductsUseCase {
  final ProductRepository _repository;

  GetLowStockProductsUseCase(this._repository);

  Future<List<ProductEntity>> call(String tenantId) {
    return _repository.getLowStockProducts(tenantId);
  }
}

class RefreshAlertsUseCase {
  final ProductRepository _productRepository;
  final StockAlertRepository _alertRepository;

  RefreshAlertsUseCase(this._productRepository, this._alertRepository);

  Future<int> call(String tenantId) async {
    final products = await _productRepository.getProducts(tenantId);
    int alertCount = 0;

    for (final product in products) {
      await _alertRepository.deleteAlertsByProductId(product.id, tenantId);

      if (product.isLowStock) {
        final now = DateTime.now();
        await _alertRepository.createAlert(
          StockAlertEntity(
            id: '',
            productId: product.id,
            productName: product.name,
            currentStock: product.stock,
            minimumStock: product.minimumStock,
            isResolved: false,
            tenantId: tenantId,
            createdAt: now,
            updatedAt: now,
          ),
        );
        alertCount++;
      }
    }

    return alertCount;
  }
}
