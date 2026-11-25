import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/doctorac_headers.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/user_avatar_circle.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../bookings/presentation/providers/bookings_provider.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../../domain/profile_model.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _picker = ImagePicker();

  String _gender = 'ذكر';
  String _avatarUrl = '';
  String? _hydratedUserId;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _hydrate(ProfileModel profile) {
    if (_hydratedUserId == profile.id && profile.id.isNotEmpty) return;
    _nameCtrl.text = profile.fullName;
    _emailCtrl.text = profile.email;
    _phoneCtrl.text = profile.phone;
    _addressCtrl.text = profile.address;
    _gender =
        (profile.gender == 'ذكر' || profile.gender == 'أنثى')
            ? profile.gender
            : 'ذكر';
    _avatarUrl = profile.avatarUrl;
    _hydratedUserId = profile.id;
  }

  Future<void> _detectAddressWithGps() async {
    final ok = await ref
        .read(userLocationProvider.notifier)
        .detectRealGpsLocation(silentIfDenied: false);
    if (!mounted) return;
    final loc = ref.read(userLocationProvider);
    if (ok) {
      setState(() {
        _addressCtrl.text = loc.detailedAddress ?? loc.displayLabel;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديد موقعك: ${_addressCtrl.text}')),
      );
    } else if (loc.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errorMessage!)),
      );
    }
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تغيير الصورة الشخصية',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'الكاميرا',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'معرض الصور',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final url = await ref
          .read(profileProvider.notifier)
          .uploadAvatar(File(picked.path));
      if (!mounted) return;
      setState(() => _avatarUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر رفع الصورة، يرجى المحاولة مرة أخرى'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _saveChanges(ProfileModel current) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = current.copyWith(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        gender: _gender,
        address: _addressCtrl.text.trim(),
        avatarUrl: _avatarUrl.isNotEmpty ? _avatarUrl : current.avatarUrl,
      );
      await ref.read(profileProvider.notifier).saveProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ بياناتك الحقيقية بنجاح!')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حفظ البيانات، تأكد من تسجيل الدخول والإنترنت.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    _hydratedUserId = null;
    await ref.read(authControllerProvider.notifier).signOut();
    ref.invalidate(profileProvider);
    ref.invalidate(bookingsProvider);
    ref.invalidate(ordersProvider);
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final locState = ref.watch(userLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, __) => const Center(
            child: Text('تعذر تحميل بيانات الحساب'),
          ),
          data: (profile) {
            if (profile.id.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 56,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'يرجى تسجيل الدخول لعرض بيانات حسابك',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SolidTealButton(
                        label: 'تسجيل الدخول',
                        onPressed: () => context.go('/login'),
                      ),
                    ],
                  ),
                ),
              );
            }

            _hydrate(profile);
            final displayAvatar =
                _avatarUrl.isNotEmpty ? _avatarUrl : profile.avatarUrl;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                _hydratedUserId = null;
                await ref.read(profileProvider.notifier).refresh();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DoctoracListHeader(
                        title: 'حسابي',
                        onBack: () => context.go('/home'),
                      ),
                      const SizedBox(height: 22),

                      // Editable Avatar + Camera Badge
                      Center(
                        child: GestureDetector(
                          onTap: _isUploadingAvatar ? null : _pickAvatar,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (_isUploadingAvatar)
                                Container(
                                  width: 102,
                                  height: 102,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.mintSurface,
                                    border: Border.all(
                                      color: AppColors.mintBorder,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                )
                              else
                                UserAvatarCircle(
                                  avatarUrl: displayAvatar,
                                  initials: profile.initials,
                                  size: 96,
                                  borderWidth: 2.5,
                                ),
                              PositionedDirectional(
                                bottom: 2,
                                end: 0,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: GestureDetector(
                          onTap: _isUploadingAvatar ? null : _pickAvatar,
                          child: const Text(
                            'تغيير الصورة الشخصية',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Full Name
                      const _FieldLabel('الاسم بالكامل'),
                      TextFormField(
                        controller: _nameCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'يرجى إدخال الاسم بالكامل'
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'أدخل اسمك الحقيقي',
                        ),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email (read-only synced with Supabase Auth email)
                      const _FieldLabel('البريد الإلكتروني'),
                      TextFormField(
                        controller: _emailCtrl,
                        readOnly: true,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Phone
                      const _FieldLabel('رقم الهاتف'),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'أدخل رقم هاتفك (مثال: 010xxxxxxxx)',
                        ),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown
                      const _FieldLabel('النوع'),
                      DropdownButtonFormField<String>(
                        key: ValueKey('gender_${profile.id}_$_gender'),
                        initialValue: _gender,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                          DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _gender = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address with real GPS auto-fill button
                      const _FieldLabel('العنوان'),
                      TextFormField(
                        controller: _addressCtrl,
                        decoration: InputDecoration(
                          hintText: 'أدخل عنوانك أو اضغط أيقونة GPS',
                          suffixIcon: IconButton(
                            tooltip: 'تحديد موقعي تلقائياً عبر GPS',
                            onPressed: locState.isDetecting
                                ? null
                                : _detectAddressWithGps,
                            icon: locState.isDetecting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    color: AppColors.primary,
                                  ),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Save Button
                      SolidTealButton(
                        label: 'حفظ التغييرات',
                        height: 54,
                        borderRadius: 16,
                        fontSize: 16,
                        isLoading: _isSaving,
                        onPressed: () => _saveChanges(profile),
                      ),

                      const SizedBox(height: 14),
                      Center(
                        child: TextButton.icon(
                          onPressed: _signOut,
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.danger,
                            size: 18,
                          ),
                          label: const Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
