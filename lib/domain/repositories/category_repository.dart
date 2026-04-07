import 'package:stockia/domain/entities/category_entity.dart';

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories(String tenantId);
  Stream<List<CategoryEntity>> watchCategories(String tenantId);
  Future<void> createCategory(CategoryEntity category);
  Future<void> updateCategory(CategoryEntity category);
  Future<void> deleteCategory(String categoryId);
}
