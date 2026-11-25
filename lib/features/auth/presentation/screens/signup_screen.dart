import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/doctorac_logo.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/auth_repository.dart';
import '../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    final loc = ref.read(userLocationProvider);
    final detectedAddress = loc.isAllEgypt ? '' : loc.displayLabel;

    final result = await ref.read(authControllerProvider.notifier).signUp(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: detectedAddress,
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (result == SignUpResult.signedIn) {
      ref.invalidate(profileProvider);
      ref.invalidate(bookingsProvider);
      ref.invalidate(ordersProvider);
      ref.read(userLocationProvider.notifier).autoDetectOnce();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء حسابك بنجاح! مرحباً بك في دكتوراك'),
        ),
      );
      context.go('/home');
    } else if (result == SignUpResult.needsEmailConfirmation) {
      final email = _emailController.text.trim();
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تأكيد البريد الإلكتروني',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
            ],
          ),
          content: Text(
            'تم إنشاء حسابك بنجاح! أرسلنا رابط تفعيل إلى:\n$email\n\nافتح الرابط في بريدك الإلكتروني ثم قم بتسجيل الدخول ببياناتك.',
            style: const TextStyle(height: 1.55, fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .resendConfirmation(email);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إعادة إرسال رابط التفعيل بنجاح'),
                      ),
                    );
                  }
                } catch (_) {}
              },
              child: const Text('إعادة إرسال الرابط'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/login');
              },
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      );
    } else {
      final err = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(AuthRepository.translateAuthError(err)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -110,
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
                    const SizedBox(height: 8),
                    const Center(
                      child: DoctoracLogo(
                        iconSize: 54,
                        fontSize: 26,
                        axis: Axis.vertical,
                        spacing: 10,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'انضم إلى دكتورك واحصل على خدماتك الصحية في مكان واحد.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _SignUpField(
                      controller: _nameController,
                      hintText: 'الاسم بالكامل',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) {
                        if (v == null || v.trim().length < 2) {
                          return 'يرجى إدخال الاسم بالكامل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    _SignUpField(
                      controller: _emailController,
                      hintText: 'البريد الإلكتروني',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || !v.contains('@')) {
                          return 'يرجى إدخال بريد إلكتروني صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    _SignUpField(
                      controller: _phoneController,
                      hintText: 'رقم الهاتف (مثال: 010xxxxxxxx)',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v != null &&
                            v.trim().isNotEmpty &&
                            v.trim().length < 10) {
                          return 'يرجى إدخال رقم هاتف صحيح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    _SignUpField(
                      controller: _passwordController,
                      hintText: 'كلمة المرور',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
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
                        if (v == null || v.length < 8) {
                          return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    _SignUpField(
                      controller: _confirmController,
                      hintText: 'تأكيد كلمة المرور',
                      prefixIcon: Icons.verified_user_outlined,
                      obscureText: _obscureConfirm,
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.primary,
                          size: 21,
                        ),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) {
                          return 'كلمة المرور غير متطابقة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 26),
                    GradientCtaButton(
                      label: 'إنشاء حساب',
                      isLoading: isLoading,
                      onPressed: _handleSignUp,
                    ),
                    const SizedBox(height: 28),
                    const Divider(color: AppColors.divider, thickness: 1),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'لديك حساب بالفعل؟ ',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Text(
                            'تسجيل الدخول',
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

class _SignUpField extends StatelessWidget {
  const _SignUpField({
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
