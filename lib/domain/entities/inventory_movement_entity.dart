import 'package:cloud_firestore/cloud_firestore.dart';

// ignore_for_file: constant_identifier_names
enum MovementType { IN, OUT, ADJUSTMENT }

extension MovementTypeExtension on MovementType {
  String get value {
    switch (this) {
      case MovementType.IN:
        return 'IN';
      case MovementType.OUT:
        return 'OUT';
      case MovementType.ADJUSTMENT:
        return 'ADJUSTMENT';
    }
  }

  String get label {
    switch (this) {
      case MovementType.IN:
        return 'Ingreso';
      case MovementType.OUT:
        return 'Salida';
      case MovementType.ADJUSTMENT:
        return 'Ajuste';
    }
  }

  static MovementType fromString(String value) {
    switch (value) {
      case 'IN':
        return MovementType.IN;
      case 'OUT':
        return MovementType.OUT;
      case 'ADJUSTMENT':
        return MovementType.ADJUSTMENT;
      default:
        throw ArgumentError('Tipo de movimiento no válido: $value');
    }
  }
}

class InventoryMovementEntity {
  final String id;
  final MovementType type;
  final int quantity;
  final String productId;
  final DateTime date;
  final String tenantId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InventoryMovementEntity({
    required this.id,
    required this.type,
    required this.quantity,
    required this.productId,
    required this.date,
    required this.tenantId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'quantity': quantity,
      'productId': productId,
      'date': Timestamp.fromDate(date),
      'tenantId': tenantId,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory InventoryMovementEntity.fromMap(String id, Map<String, dynamic> map) {
    return InventoryMovementEntity(
      id: id,
      type: MovementTypeExtension.fromString(map['type'] as String),
      quantity: map['quantity'] as int,
      productId: map['productId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      tenantId: map['tenantId'] as String,
      notes: map['notes'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory InventoryMovementEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryMovementEntity.fromMap(doc.id, data);
  }
}
