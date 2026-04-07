import 'package:cloud_firestore/cloud_firestore.dart';

class StockAlertEntity {
  final String id;
  final String productId;
  final String productName;
  final int currentStock;
  final int minimumStock;
  final bool isResolved;
  final String tenantId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StockAlertEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.currentStock,
    required this.minimumStock,
    required this.isResolved,
    required this.tenantId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'currentStock': currentStock,
      'minimumStock': minimumStock,
      'isResolved': isResolved,
      'tenantId': tenantId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory StockAlertEntity.fromMap(String id, Map<String, dynamic> map) {
    return StockAlertEntity(
      id: id,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      currentStock: map['currentStock'] as int,
      minimumStock: map['minimumStock'] as int,
      isResolved: map['isResolved'] as bool,
      tenantId: map['tenantId'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory StockAlertEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockAlertEntity.fromMap(doc.id, data);
  }
}
