import 'package:cloud_firestore/cloud_firestore.dart';

class UserEntity {
  final String id;
  final String email;
  final String tenantId;
  final String? displayName;

  const UserEntity({
    required this.id,
    required this.email,
    required this.tenantId,
    this.displayName,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? tenantId,
    String? displayName,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      tenantId: tenantId ?? this.tenantId,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'tenantId': tenantId, 'displayName': displayName};
  }

  factory UserEntity.fromMap(String id, Map<String, dynamic> map) {
    return UserEntity(
      id: id,
      email: map['email'] as String,
      tenantId: map['tenantId'] as String,
      displayName: map['displayName'] as String?,
    );
  }

  factory UserEntity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserEntity.fromMap(doc.id, data);
  }
}
