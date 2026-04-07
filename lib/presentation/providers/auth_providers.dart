import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/domain/entities/user_entity.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'package:stockia/domain/use_cases/auth_use_cases.dart';
import 'package:stockia/presentation/providers/core_providers.dart';

// ── Use cases ──
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final signInWithSocialUseCaseProvider = Provider<SignInWithSocialUseCase>((
  ref,
) {
  return SignInWithSocialUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.watch(authRepositoryProvider));
});

final updateUserProfileUseCaseProvider = Provider<UpdateUserProfileUseCase>((
  ref,
) {
  return UpdateUserProfileUseCase(ref.watch(authRepositoryProvider));
});

final updateTenantUseCaseProvider = Provider<UpdateTenantUseCase>((ref) {
  return UpdateTenantUseCase(ref.watch(authRepositoryProvider));
});

final updateEmailUseCaseProvider = Provider<UpdateEmailUseCase>((ref) {
  return UpdateEmailUseCase(ref.watch(authRepositoryProvider));
});

final authProviderTypeProvider = Provider<String?>((ref) {
  return ref.watch(authRepositoryProvider).getAuthProvider();
});

// ── Auth notifier ──
class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignInWithSocialUseCase _signInWithSocial;
  final SignOutUseCase _signOut;

  AuthNotifier({
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required SignInWithSocialUseCase signInWithSocial,
    required SignOutUseCase signOut,
  }) : _signIn = signIn,
       _signUp = signUp,
       _signInWithSocial = signInWithSocial,
       _signOut = signOut,
       super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _signIn(email: email, password: password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(SignUpData data) async {
    state = const AsyncValue.loading();
    try {
      final user = await _signUp(data);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> socialLogin(SocialAuthProvider provider) async {
    state = const AsyncValue.loading();
    try {
      final user = await _signInWithSocial(provider);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
      return AuthNotifier(
        signIn: ref.watch(signInUseCaseProvider),
        signUp: ref.watch(signUpUseCaseProvider),
        signInWithSocial: ref.watch(signInWithSocialUseCaseProvider),
        signOut: ref.watch(signOutUseCaseProvider),
      );
    });
