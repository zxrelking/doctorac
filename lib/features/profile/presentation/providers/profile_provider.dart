import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';
import '../../domain/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileNotifier extends AsyncNotifier<ProfileModel> {
  @override
  Future<ProfileModel> build() async {
    return ref.watch(profileRepositoryProvider).fetchProfile();
  }

  Future<void> saveProfile(ProfileModel updated) async {
    final repo = ref.read(profileRepositoryProvider);
    final saved = await repo.updateProfile(updated);
    state = AsyncData(saved);
  }

  Future<String> uploadAvatar(File file) async {
    final repo = ref.read(profileRepositoryProvider);
    final url = await repo.uploadAvatar(file);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(avatarUrl: url));
    }
    return url;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).fetchProfile(),
    );
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileModel>(
  ProfileNotifier.new,
);

/// Selected user location shown in the Home screen header ("المنصورة، مصر").
final selectedLocationProvider = StateProvider<String>((ref) {
  return 'المنصورة، مصر';
});
