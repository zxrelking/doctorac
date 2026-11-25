import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repo) : super(const AsyncData(null));

  final AuthRepository _repo;

  Future<bool> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repo.signInWithEmail(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<SignUpResult?> signUp({
    required String fullName,
    required String email,
    required String password,
    String phone = '',
    String address = '',
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.signUpWithEmail(
        fullName: fullName,
        email: email,
        password: password,
        phone: phone,
        address: address,
      );
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> launchOAuth(OAuthProvider provider) async {
    state = const AsyncLoading();
    try {
      final launched = await _repo.signInWithOAuth(provider);
      state = const AsyncData(null);
      return launched;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> resendConfirmation(String email) async {
    await _repo.resendConfirmationEmail(email);
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    try {
      await _repo.sendPasswordResetEmail(email);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    state = const AsyncLoading();
    try {
      await _repo.updatePassword(newPassword);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
