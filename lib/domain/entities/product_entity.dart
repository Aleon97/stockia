import 'package:cloud_firestore/cloud_firestore.dart';

class ProductEntity {
  final String id;
  final String name;
  final String categoryId;
  final int stock;
  final int minimumStock;
  final double costPrice;
  final double salePrice;
  final String tenantId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.stock,
    required this.minimumStock,
    required this.costPrice,
    required this.salePrice,
    required this.tenantId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stock <= minimumStock;

  ProductEntity copyWith({
    String? id,
    String? name,
    String? categoryId,
    int? stock,
    int? minimumStock,
    double? costPrice,
    double? salePrice,
    String? tenantId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      stock: stock ?? this.stock,
      minimumStock: minimumStock ?? this.minimumStock,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      tenantId: tenantId ?? this.tenantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryId': categoryId,
      'stock': stock,
      'minimumStock': minimumStock,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'tenantId': tenantId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProductEntity.fromMap(String id, Map<String, dynamic> map) {
    return ProductEntity(
      id: id,
      name: map['name'] as String,
      categoryId: map['categoryId'] as String,
      stock: map['stock'] as int,
      minimumStock: map['minimumStock'] as int,
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      salePrice:
          (map['salePrice'] as num?)?.toDouble() ??
          (map['price'] as num?)?.toDouble() ??
          0.0,
      tenantId: map['tenantId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory ProductEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductEntity.fromMap(doc.id, data);
  }
}
