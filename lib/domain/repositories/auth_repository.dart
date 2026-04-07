import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:stockia/domain/entities/user_entity.dart';

enum SocialAuthProvider { google, microsoft, apple }

class SignUpData {
  final String email;
  final String password;
  final String companyName;
  final String nit;
  final String businessType;
  final String legalRepresentative;

  const SignUpData({
    required this.email,
    required this.password,
    required this.companyName,
    required this.nit,
    required this.businessType,
    required this.legalRepresentative,
  });
}

abstract class AuthRepository {
  Stream<firebase_auth.User?> get authStateChanges;
  firebase_auth.User? get currentUser;

  Future<UserEntity> signIn({required String email, required String password});
  Future<UserEntity> signUp(SignUpData data);
  Future<UserEntity> signInWithSocial(SocialAuthProvider provider);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUserEntity();
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> updateUserProfile({required String displayName});
  Future<void> updateTenant({
    required String tenantId,
    required String name,
    required String nit,
    required String legalRepresentative,
  });
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  });
  Future<bool> isEmailInUse(String email);
  String? getAuthProvider();
}
