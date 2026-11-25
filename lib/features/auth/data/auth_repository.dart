import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';

enum SignUpResult { signedIn, needsEmailConfirmation }

class AuthRepository {
  SupabaseClient? get _client => SupabaseConfig.clientOrNull;

  bool get isSignedIn {
    final client = _client;
    if (client != null) {
      return client.auth.currentSession != null;
    }
    return false;
  }

  User? get currentUser => _client?.auth.currentUser;

  String? get currentUserId => _client?.auth.currentUser?.id;

  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('لم يتم الاتصال بالخادم، تحقق من الإنترنت.');
    }
    final res = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (res.session == null) {
      throw const AuthException('يرجى تأكيد بريدك الإلكتروني أولاً قبل الدخول.');
    }
  }

  Future<SignUpResult> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
    String phone = '',
    String address = '',
  }) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('لم يتم الاتصال بالخادم، تحقق من الإنترنت.');
    }
    final res = await client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: SupabaseConfig.oauthRedirectUrl,
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
      },
    );

    if (res.session != null && res.user != null) {
      // Ensure profile table immediately reflects exact entered info
      try {
        await client.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': fullName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
        });
      } catch (_) {
        // Trigger already handles profile insert
      }
      return SignUpResult.signedIn;
    }

    return SignUpResult.needsEmailConfirmation;
  }

  Future<void> resendConfirmationEmail(String email) async {
    final client = _client;
    if (client == null) return;
    await client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: SupabaseConfig.oauthRedirectUrl,
    );
  }

  /// Launches Google / Apple OAuth in the external browser and returns back
  /// via deep link `io.doctorac.app://login-callback/`.
  /// The calling screen listens to `authStateChanges` for `AuthChangeEvent.signedIn`.
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('لم يتم الاتصال بالخادم، تحقق من الإنترنت.');
    }
    return client.auth.signInWithOAuth(
      provider,
      redirectTo: SupabaseConfig.oauthRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final client = _client;
    if (client == null) return;
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: SupabaseConfig.oauthRedirectUrl,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    final client = _client;
    if (client == null) {
      throw const AuthException('لم يتم الاتصال بالخادم.');
    }
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  static String translateAuthError(Object? error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      }
      if (msg.contains('email not confirmed')) {
        return 'يرجى تأكيد بريدك الإلكتروني أولاً عبر الرابط المرسل إلى بريدك.';
      }
      if (msg.contains('user already registered') ||
          msg.contains('already exists')) {
        return 'هذا البريد الإلكتروني مسجل بالفعل، يمكنك تسجيل الدخول مباشرة.';
      }
      if (msg.contains('provider is not enabled') ||
          msg.contains('unsupported provider')) {
        return 'تسجيل الدخول عبر جوجل غير مفعّل بعد في لوحة Supabase.';
      }
      if (msg.contains('rate limit') || msg.contains('too many')) {
        return 'تم تجاوز عدد المحاولات المسموح به، يرجى الانتظار قليلاً ثم المحاولة.';
      }
      if (msg.contains('password')) {
        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';
      }
      return error.message;
    }
    return 'حدث خطأ غير متوقع، يرجى التحقق من اتصال الإنترنت والمحاولة مرة أخرى.';
  }
}
