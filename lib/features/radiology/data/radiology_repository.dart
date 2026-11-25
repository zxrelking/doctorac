import '../../../core/config/supabase_config.dart';
import '../../../core/data/fallback_seed_data.dart';
import '../domain/radiology_model.dart';

class RadiologyRepository {
  Future<List<RadiologyCenterModel>> fetchCentersWithScans() async {
    final client = SupabaseConfig.clientOrNull;
    if (client == null) {
      return FallbackSeedData.radiologyCenters;
    }
    try {
      final response = await client
          .from('radiology_centers')
          .select('*, radiology_scans(*)')
          .order('rating', ascending: false);
      final list = (response as List<dynamic>)
          .map((e) => RadiologyCenterModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return list.isEmpty ? FallbackSeedData.radiologyCenters : list;
    } catch (_) {
      return FallbackSeedData.radiologyCenters;
    }
  }

  Future<RadiologyCenterModel?> fetchCenterById(String id) async {
    final centers = await fetchCentersWithScans();
    for (final c in centers) {
      if (c.id == id) return c;
    }
    return centers.isNotEmpty ? centers.first : null;
  }
}
