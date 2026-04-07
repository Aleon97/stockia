import 'package:cloud_firestore/cloud_firestore.dart';

class TenantEntity {
  final String id;
  final String name;
  final String nit;
  final String businessType;
  final String legalRepresentative;
  final DateTime createdAt;

  const TenantEntity({
    required this.id,
    required this.name,
    required this.nit,
    required this.businessType,
    required this.legalRepresentative,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nit': nit,
      'businessType': businessType,
      'legalRepresentative': legalRepresentative,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory TenantEntity.fromMap(String id, Map<String, dynamic> map) {
    return TenantEntity(
      id: id,
      name: map['name'] as String,
      nit: map['nit'] as String? ?? '',
      businessType: map['businessType'] as String? ?? '',
      legalRepresentative: map['legalRepresentative'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory TenantEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TenantEntity.fromMap(doc.id, data);
  }
}
