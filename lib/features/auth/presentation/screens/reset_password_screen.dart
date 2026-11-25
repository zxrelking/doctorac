import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/doctorac_logo.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool get _hasMinLength => _newPassController.text.length >= 8;
  bool get _hasLettersAndNumbers =>
      RegExp(r'(?=.*[A-Za-z\u0600-\u06FF])(?=.*\d)')
          .hasMatch(_newPassController.text);

  @override
  void initState() {
    super.initState();
    _newPassController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .updatePassword(_newPassController.text);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث كلمة المرور بنجاح! يمكنك تسجيل الدخول الآن.'),
        ),
      );
      context.go('/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تحديث كلمة المرور. يرجى المحاولة لاحقاً.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Back arrow + Doctorac logo (matching Reset Password.png)
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const DoctoracLogo(iconSize: 28, fontSize: 21),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'إنشاء كلمة مرور جديدة',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'اختر كلمة مرور قوية لحماية حسابك، واستخدمها في تسجيل الدخول لاحقاً.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                // Elevated white card container matching Figma
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'كلمة المرور الجديدة',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _newPassController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputSoftFill,
                          hintText: 'أدخل كلمة المرور الجديدة',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.primary,
                            size: 21,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscureNew = !_obscureNew),
                            icon: Icon(
                              _obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.primary,
                              size: 21,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.2,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'يجب أن تكون 8 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'تأكيد كلمة المرور',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmPassController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputSoftFill,
                          hintText: 'أعد إدخال كلمة المرور',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.primary,
                            size: 21,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.primary,
                              size: 21,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.2,
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v != _newPassController.text) {
                            return 'كلمتا المرور غير متطابقتين';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _ValidationRuleRow(
                        text: '8 أحرف على الأقل.',
                        satisfied: _hasMinLength,
                      ),
                      const SizedBox(height: 6),
                      _ValidationRuleRow(
                        text: 'يُفضّل استخدام حروف وأرقام معاً.',
                        satisfied: _hasLettersAndNumbers,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                GradientCtaButton(
                  label: 'تحديث كلمة المرور',
                  isLoading: isLoading,
                  onPressed: _handleUpdate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ValidationRuleRow extends StatelessWidget {
  const _ValidationRuleRow({
    required this.text,
    required this.satisfied,
  });

  final String text;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle_rounded : Icons.circle,
          size: satisfied ? 14 : 6,
          color: satisfied ? AppColors.primary : AppColors.textMuted,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: satisfied ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: satisfied ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
