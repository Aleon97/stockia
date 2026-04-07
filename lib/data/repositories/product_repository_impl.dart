import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockia/domain/entities/product_entity.dart';
import 'package:stockia/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('products');

  @override
  Future<List<ProductEntity>> getProducts(String tenantId) async {
    final snapshot = await _collection
        .where('tenantId', isEqualTo: tenantId)
        .get();

    final products = snapshot.docs
        .map((doc) => ProductEntity.fromFirestore(doc))
        .toList();
    products.sort((a, b) => a.name.compareTo(b.name));
    return products;
  }

  @override
  Stream<List<ProductEntity>> watchProducts(String tenantId) {
    return _collection.where('tenantId', isEqualTo: tenantId).snapshots().map((
      snapshot,
    ) {
      final products = snapshot.docs
          .map((doc) => ProductEntity.fromFirestore(doc))
          .toList();
      products.sort((a, b) => a.name.compareTo(b.name));
      return products;
    });
  }

  @override
  Future<ProductEntity?> getProductById(String productId) async {
    final doc = await _collection.doc(productId).get();
    if (!doc.exists) return null;
    return ProductEntity.fromFirestore(doc);
  }

  @override
  Future<void> createProduct(ProductEntity product) async {
    await _collection.add(product.toMap());
  }

  @override
  Future<void> updateProduct(ProductEntity product) async {
    await _collection.doc(product.id).update(product.toMap());
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await _collection.doc(productId).delete();
  }

  @override
  Future<void> updateStock(String productId, int newStock) async {
    await _collection.doc(productId).update({
      'stock': newStock,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<List<ProductEntity>> getLowStockProducts(String tenantId) async {
    final snapshot = await _collection
        .where('tenantId', isEqualTo: tenantId)
        .get();

    return snapshot.docs
        .map((doc) => ProductEntity.fromFirestore(doc))
        .where((product) => product.isLowStock)
        .toList();
  }
}
