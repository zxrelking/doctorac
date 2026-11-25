import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/data/fallback_seed_data.dart';
import '../domain/pharmacy_model.dart';

class PharmaciesRepository {
  Future<List<PharmacyModel>> fetchPharmacies() async {
    final client = SupabaseConfig.clientOrNull;
    if (client == null) {
      return FallbackSeedData.pharmacies;
    }
    try {
      final response = await client
          .from('pharmacies')
          .select()
          .order('distance_km', ascending: true);
      final list = (response as List<dynamic>)
          .map((e) => PharmacyModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return list.isEmpty ? FallbackSeedData.pharmacies : list;
    } catch (_) {
      return FallbackSeedData.pharmacies;
    }
  }

  Future<PharmacyModel?> fetchPharmacyById(String id) async {
    final list = await fetchPharmacies();
    for (final p in list) {
      if (p.id == id) return p;
    }
    return list.isNotEmpty ? list.first : null;
  }

  /// Uploads prescription photo to Supabase Storage bucket `prescriptions`
  /// and returns its public URL (or local path in preview mode).
  Future<String> uploadPrescription(File file) async {
    final client = SupabaseConfig.clientOrNull;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return file.path;
    }
    final ext = file.path.split('.').last.toLowerCase();
    final storagePath =
        '$userId/rx_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage.from('prescriptions').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(upsert: true),
        );
    return client.storage.from('prescriptions').getPublicUrl(storagePath);
  }
}
