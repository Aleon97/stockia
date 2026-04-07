import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:stockia/domain/entities/user_entity.dart';
import 'package:stockia/domain/entities/tenant_entity.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn? _googleSignIn;

  AuthRepositoryImpl({
    required firebase_auth.FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore,
       _googleSignIn = kIsWeb ? null : (googleSignIn ?? GoogleSignIn());

  @override
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  @override
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Error al iniciar sesión');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      throw Exception('Usuario no encontrado en la base de datos');
    }

    // Asegurar registro de email (para usuarios existentes sin registro)
    final emailDoc = _firestore.collection('registered_emails').doc(email);
    final emailSnap = await emailDoc.get();
    if (!emailSnap.exists) {
      await emailDoc.set({
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return UserEntity.fromFirestore(userDoc);
  }

  @override
  Future<UserEntity> signUp(SignUpData data) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: data.email,
      password: data.password,
    );

    final user = credential.user;
    if (user == null) {
      throw Exception('Error al crear la cuenta');
    }

    // Enviar verificación de correo (no bloquear el registro si falla)
    try {
      await user.sendEmailVerification();
    } catch (_) {
      // Silenciar error de verificación de correo
    }

    return _createTenantAndUser(
      uid: user.uid,
      email: data.email,
      displayName: data.legalRepresentative,
      companyName: data.companyName,
      nit: data.nit,
      businessType: data.businessType,
      legalRepresentative: data.legalRepresentative,
    );
  }

  @override
  Future<UserEntity> signInWithSocial(SocialAuthProvider provider) async {
    final firebase_auth.UserCredential userCredential;

    if (kIsWeb) {
      // En web, usar signInWithPopup directamente
      final firebase_auth.AuthProvider authProvider;
      switch (provider) {
        case SocialAuthProvider.google:
          authProvider = firebase_auth.GoogleAuthProvider();
          break;
        case SocialAuthProvider.microsoft:
          final msProvider = firebase_auth.MicrosoftAuthProvider();
          msProvider.addScope('User.Read');
          authProvider = msProvider;
          break;
        case SocialAuthProvider.apple:
          final appleProvider = firebase_auth.AppleAuthProvider();
          appleProvider.addScope('email');
          appleProvider.addScope('name');
          authProvider = appleProvider;
          break;
      }
      userCredential = await _firebaseAuth.signInWithPopup(authProvider);
    } else {
      // En nativo, usar el flujo normal con credentials
      final firebase_auth.AuthCredential credential;
      switch (provider) {
        case SocialAuthProvider.google:
          credential = await _getGoogleCredential();
          break;
        case SocialAuthProvider.microsoft:
          credential = await _getMicrosoftCredential();
          break;
        case SocialAuthProvider.apple:
          credential = await _getAppleCredential();
          break;
      }
      userCredential = await _firebaseAuth.signInWithCredential(credential);
    }

    final user = userCredential.user;
    if (user == null) {
      throw Exception('Error al iniciar sesión con proveedor social');
    }

    // Verificar si ya existe en Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      // Asegurar registro de email (para usuarios existentes sin registro)
      final emailDoc = _firestore
          .collection('registered_emails')
          .doc(user.email ?? '');
      final emailSnap = await emailDoc.get();
      if (!emailSnap.exists && (user.email ?? '').isNotEmpty) {
        await emailDoc.set({
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return UserEntity.fromFirestore(userDoc);
    }

    // Primera vez: crear tenant y usuario
    return _createTenantAndUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      companyName: user.displayName ?? 'Mi Empresa',
      nit: '',
      businessType: '',
      legalRepresentative: user.displayName ?? '',
    );
  }

  Future<firebase_auth.AuthCredential> _getGoogleCredential() async {
    final googleSignIn = _googleSignIn;
    if (googleSignIn == null) {
      throw Exception('Google Sign-In no disponible en esta plataforma');
    }
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Inicio de sesión con Google cancelado');
    }
    final googleAuth = await googleUser.authentication;
    return firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
  }

  Future<firebase_auth.AuthCredential> _getMicrosoftCredential() async {
    final provider = firebase_auth.MicrosoftAuthProvider();
    provider.addScope('User.Read');
    final userCredential = await _firebaseAuth.signInWithProvider(provider);
    final oauthCredential = userCredential.credential;
    if (oauthCredential == null) {
      throw Exception('Error al obtener credenciales de Microsoft');
    }
    return oauthCredential;
  }

  Future<firebase_auth.AuthCredential> _getAppleCredential() async {
    final provider = firebase_auth.AppleAuthProvider();
    provider.addScope('email');
    provider.addScope('name');
    final userCredential = await _firebaseAuth.signInWithProvider(provider);
    final oauthCredential = userCredential.credential;
    if (oauthCredential == null) {
      throw Exception('Error al obtener credenciales de Apple');
    }
    return oauthCredential;
  }

  Future<UserEntity> _createTenantAndUser({
    required String uid,
    required String email,
    required String? displayName,
    required String companyName,
    required String nit,
    required String businessType,
    required String legalRepresentative,
  }) async {
    final tenantRef = _firestore.collection('tenants').doc();
    final tenant = TenantEntity(
      id: tenantRef.id,
      name: companyName,
      nit: nit,
      businessType: businessType,
      legalRepresentative: legalRepresentative,
      createdAt: DateTime.now(),
    );

    final userEntity = UserEntity(
      id: uid,
      email: email,
      tenantId: tenantRef.id,
      displayName: displayName,
    );

    // Usar batch para crear ambos documentos atómicamente
    final batch = _firestore.batch();
    batch.set(tenantRef, tenant.toMap());
    batch.set(_firestore.collection('users').doc(uid), userEntity.toMap());
    // Registrar email para validación de duplicados
    batch.set(_firestore.collection('registered_emails').doc(email), {
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    return userEntity;
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn?.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUserEntity() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return null;

    return UserEntity.fromFirestore(userDoc);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No hay usuario autenticado');
    }

    final credential = firebase_auth.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> updateUserProfile({required String displayName}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado');
    }

    await _firestore.collection('users').doc(user.uid).update({
      'displayName': displayName,
    });
  }

  @override
  Future<void> updateTenant({
    required String tenantId,
    required String name,
    required String nit,
    required String legalRepresentative,
  }) async {
    await _firestore.collection('tenants').doc(tenantId).update({
      'name': name,
      'nit': nit,
      'legalRepresentative': legalRepresentative,
    });
  }

  @override
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No hay usuario autenticado');
    }

    // Reauthenticate first
    final credential = firebase_auth.EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Send verification to new email before updating
    await user.verifyBeforeUpdateEmail(newEmail);

    // Update email in Firestore and registered_emails atomically
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(user.uid), {
      'email': newEmail,
    });
    // Remove old email registration
    batch.delete(_firestore.collection('registered_emails').doc(user.email!));
    // Register new email
    batch.set(_firestore.collection('registered_emails').doc(newEmail), {
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<bool> isEmailInUse(String email) async {
    // 1. Verificar en registered_emails (usuarios nuevos o migrados)
    final doc = await _firestore
        .collection('registered_emails')
        .doc(email)
        .get();
    if (doc.exists) return true;

    // 2. Fallback: buscar en colección users (usuarios pre-migración)
    final usersQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (usersQuery.docs.isNotEmpty) {
      // Backfill: registrar email para futuras consultas rápidas
      final uid = usersQuery.docs.first.id;
      await _firestore.collection('registered_emails').doc(email).set({
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    }

    return false;
  }

  @override
  String? getAuthProvider() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return 'google';
      if (info.providerId == 'microsoft.com') return 'microsoft';
    }
    return 'password';
  }
}
