import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryEntity {
  final String id;
  final String name;
  final String tenantId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.tenantId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'tenantId': tenantId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CategoryEntity.fromMap(String id, Map<String, dynamic> map) {
    return CategoryEntity(
      id: id,
      name: map['name'] as String,
      tenantId: map['tenantId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory CategoryEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryEntity.fromMap(doc.id, data);
  }
}
