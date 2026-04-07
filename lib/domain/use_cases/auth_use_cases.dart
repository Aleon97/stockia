import 'package:stockia/domain/entities/user_entity.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<UserEntity> call({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }
}

class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<UserEntity> call(SignUpData data) {
    return _repository.signUp(data);
  }
}

class SignInWithSocialUseCase {
  final AuthRepository _repository;

  SignInWithSocialUseCase(this._repository);

  Future<UserEntity> call(SocialAuthProvider provider) {
    return _repository.signInWithSocial(provider);
  }
}

class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  Future<void> call() {
    return _repository.signOut();
  }
}

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<UserEntity?> call() {
    return _repository.getCurrentUserEntity();
  }
}

class ChangePasswordUseCase {
  final AuthRepository _repository;

  ChangePasswordUseCase(this._repository);

  Future<void> call({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

class UpdateUserProfileUseCase {
  final AuthRepository _repository;

  UpdateUserProfileUseCase(this._repository);

  Future<void> call({required String displayName}) {
    return _repository.updateUserProfile(displayName: displayName);
  }
}

class UpdateTenantUseCase {
  final AuthRepository _repository;

  UpdateTenantUseCase(this._repository);

  Future<void> call({
    required String tenantId,
    required String name,
    required String nit,
    required String legalRepresentative,
  }) {
    return _repository.updateTenant(
      tenantId: tenantId,
      name: name,
      nit: nit,
      legalRepresentative: legalRepresentative,
    );
  }
}

class UpdateEmailUseCase {
  final AuthRepository _repository;

  UpdateEmailUseCase(this._repository);

  Future<void> call({
    required String newEmail,
    required String currentPassword,
  }) {
    return _repository.updateEmail(
      newEmail: newEmail,
      currentPassword: currentPassword,
    );
  }
}
