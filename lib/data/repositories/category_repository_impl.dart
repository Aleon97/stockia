import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stockia/domain/entities/category_entity.dart';
import 'package:stockia/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('categories');

  @override
  Future<List<CategoryEntity>> getCategories(String tenantId) async {
    final snapshot = await _collection
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((doc) => CategoryEntity.fromFirestore(doc))
        .toList();
  }

  @override
  Stream<List<CategoryEntity>> watchCategories(String tenantId) {
    return _collection
        .where('tenantId', isEqualTo: tenantId)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CategoryEntity.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<void> createCategory(CategoryEntity category) async {
    await _collection.add(category.toMap());
  }

  @override
  Future<void> updateCategory(CategoryEntity category) async {
    await _collection.doc(category.id).update(category.toMap());
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _collection.doc(categoryId).delete();
  }
}
