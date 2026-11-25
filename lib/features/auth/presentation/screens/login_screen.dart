import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/doctorac_logo.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  StreamSubscription<AuthState>? _authSub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Listen for real OAuth deep-link callback (Google / Apple) or session restore
    _authSub = ref.read(authRepositoryProvider).authStateChanges?.listen(
      (authState) {
        if (!mounted || _navigated) return;
        if (authState.event == AuthChangeEvent.signedIn &&
            authState.session != null) {
          _onSignedInSuccess();
        } else if (authState.event == AuthChangeEvent.passwordRecovery) {
          context.push('/reset-password');
        }
      },
    );
  }

  void _onSignedInSuccess() {
    if (_navigated || !mounted) return;
    _navigated = true;
    ref.invalidate(profileProvider);
    ref.invalidate(bookingsProvider);
    ref.invalidate(ordersProvider);
    ref.read(userLocationProvider.notifier).autoDetectOnce();
    context.go('/home');
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final ok = await ref.read(authControllerProvider.notifier).signIn(
          email,
          _passwordController.text,
        );
    if (!mounted) return;
    if (ok) {
      _onSignedInSuccess();
    } else {
      final err = ref.read(authControllerProvider).error;
      final isUnconfirmed = err is AuthException &&
          err.message.toLowerCase().contains('email not confirmed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(AuthRepository.translateAuthError(err)),
          action: isUnconfirmed
              ? SnackBarAction(
                  label: 'إعادة إرسال',
                  textColor: AppColors.primaryLight,
                  onPressed: () async {
                    try {
                      await ref
                          .read(authControllerProvider.notifier)
                          .resendConfirmation(email);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تم إرسال رابط التفعيل إلى بريدك الإلكتروني بنجاح.',
                          ),
                        ),
                      );
                    } catch (_) {}
                  },
                )
              : null,
        ),
      );
    }
  }

  Future<void> _handleOAuth(OAuthProvider provider) async {
    final launched = await ref
        .read(authControllerProvider.notifier)
        .launchOAuth(provider);
    if (!mounted) return;
    if (!launched) {
      final err = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(AuthRepository.translateAuthError(err)),
        ),
      );
    }
    // Note: Do NOT navigate to /home yet! _authSub automatically navigates
    // to /home once the browser redirects back to io.doctorac.app://login-callback/
    // with a verified Supabase session.
  }

  Future<void> _handleForgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'استعادة كلمة المرور',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لتعيين كلمة مرور جديدة.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إرسال الرابط'),
          ),
        ],
      ),
    );

    if (sent == true && emailCtrl.text.trim().contains('@') && mounted) {
      final ok = await ref
          .read(authControllerProvider.notifier)
          .sendPasswordReset(emailCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني.'
                : 'تعذر إرسال الرابط، تأكد من البريد الإلكتروني وحاول مرة أخرى.',
          ),
        ),
      );
    }
    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.mintGlow.withValues(alpha: 0.75),
                    AppColors.background.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    const Center(
                      child: DoctoracLogo(
                        iconSize: 56,
                        fontSize: 27,
                        axis: Axis.vertical,
                        spacing: 10,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'مرحباً بعودتك',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'سجّل دخولك للوصول إلى خدماتك الصحية بسهولة.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'البريد الإلكتروني',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AuthTextField(
                      controller: _emailController,
                      hintText: 'أدخل بريدك الإلكتروني',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.mail_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'يرجى إدخال البريد الإلكتروني';
                        }
                        if (!v.contains('@')) {
                          return 'يرجى إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'كلمة المرور',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AuthTextField(
                      controller: _passwordController,
                      hintText: 'أدخل كلمة المرور',
                      obscureText: _obscurePassword,
                      prefixIcon: Icons.lock_outline_rounded,
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.primary,
                          size: 21,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'يرجى إدخال كلمة المرور';
                        }
                        if (v.length < 6) {
                          return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: _handleForgotPassword,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientCtaButton(
                      label: 'تسجيل الدخول',
                      isLoading: isLoading,
                      onPressed: _handleLogin,
                    ),
                    const SizedBox(height: 28),
                    const Row(
                      children: [
                        Expanded(
                          child: Divider(color: AppColors.divider, thickness: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'أو سجّل الدخول باستخدام',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: AppColors.divider, thickness: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _OAuthButton(
                            label: 'Google',
                            icon: const Text(
                              'G',
                              style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onTap: isLoading
                                ? null
                                : () => _handleOAuth(OAuthProvider.google),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _OAuthButton(
                            label: 'Apple',
                            icon: const Icon(
                              Icons.apple_rounded,
                              color: AppColors.textPrimary,
                              size: 22,
                            ),
                            onTap: isLoading
                                ? null
                                : () => _handleOAuth(OAuthProvider.apple),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ليس لديك حساب؟ ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/signup'),
                          child: const Text(
                            'إنشاء حساب جديد',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            prefixIcon,
            color: AppColors.primary,
            size: 21,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
