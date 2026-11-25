import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../domain/profile_model.dart';

class ProfileRepository {
  /// Always fetches the REAL authenticated user's profile from Supabase.
  /// Never substitutes hardcoded fake names/emails/phones.
  Future<ProfileModel> fetchProfile() async {
    final client = SupabaseConfig.clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return ProfileModel.empty;
    }

    final meta = user.userMetadata ?? <String, dynamic>{};
    final metaName = (meta['full_name'] ?? meta['name'] ?? '').toString().trim();
    final metaAvatar =
        (meta['avatar_url'] ?? meta['picture'] ?? '').toString().trim();
    final metaPhone = (meta['phone'] ?? '').toString().trim();
    final metaAddress = (meta['address'] ?? '').toString().trim();
    final metaGender = (meta['gender'] ?? 'ذكر').toString().trim();
    final userEmail = user.email ?? '';

    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        final created = ProfileModel(
          id: user.id,
          fullName: metaName.isNotEmpty
              ? metaName
              : (userEmail.contains('@') ? userEmail.split('@').first : ''),
          email: userEmail,
          phone: metaPhone,
          gender: (metaGender == 'أنثى' || metaGender == 'ذكر')
              ? metaGender
              : 'ذكر',
          address: metaAddress,
          avatarUrl: metaAvatar,
        );
        await client.from('profiles').upsert({
          'id': user.id,
          ...created.toUpdateJson(),
        });
        return created;
      }

      final parsed = ProfileModel.fromJson(data);
      // Fill empty fields from Google/Auth metadata if present
      final merged = parsed.copyWith(
        fullName: parsed.fullName.isNotEmpty ? parsed.fullName : metaName,
        email: parsed.email.isNotEmpty ? parsed.email : userEmail,
        avatarUrl:
            parsed.avatarUrl.isNotEmpty ? parsed.avatarUrl : metaAvatar,
      );
      return merged;
    } catch (_) {
      return ProfileModel(
        id: user.id,
        fullName: metaName,
        email: userEmail,
        phone: metaPhone,
        gender:
            (metaGender == 'أنثى' || metaGender == 'ذكر') ? metaGender : 'ذكر',
        address: metaAddress,
        avatarUrl: metaAvatar,
      );
    }
  }

  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    final client = SupabaseConfig.clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw Exception('يجب تسجيل الدخول لحفظ التغييرات');
    }

    final updated = await client
        .from('profiles')
        .upsert({
          'id': user.id,
          ...profile.toUpdateJson(),
        })
        .select()
        .single();

    // Keep auth.users metadata in sync so re-login always reflects real info
    try {
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': profile.fullName,
            'phone': profile.phone,
            'gender': profile.gender,
            'address': profile.address,
            'avatar_url': profile.avatarUrl,
          },
        ),
      );
    } catch (_) {
      // Profiles table already persisted successfully
    }

    return ProfileModel.fromJson(updated);
  }

  Future<String> uploadAvatar(File file) async {
    final client = SupabaseConfig.clientOrNull;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      throw Exception('يجب تسجيل الدخول لتغيير الصورة الشخصية');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final path =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage.from('avatars').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    final publicUrl = client.storage.from('avatars').getPublicUrl(path);

    await client
        .from('profiles')
        .update({'avatar_url': publicUrl}).eq('id', user.id);

    try {
      await client.auth.updateUser(
        UserAttributes(data: {'avatar_url': publicUrl}),
      );
    } catch (_) {}

    return publicUrl;
  }
}
