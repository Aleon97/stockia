import 'package:stockia/domain/entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getProducts(String tenantId);
  Stream<List<ProductEntity>> watchProducts(String tenantId);
  Future<ProductEntity?> getProductById(String productId);
  Future<void> createProduct(ProductEntity product);
  Future<void> updateProduct(ProductEntity product);
  Future<void> deleteProduct(String productId);
  Future<void> updateStock(String productId, int newStock);
  Future<List<ProductEntity>> getLowStockProducts(String tenantId);
}
