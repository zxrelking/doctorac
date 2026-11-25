import '../../../core/config/supabase_config.dart';
import '../../../core/data/fallback_seed_data.dart';
import '../domain/doctor_model.dart';

class DoctorsRepository {
  Future<List<DoctorModel>> fetchDoctors() async {
    final client = SupabaseConfig.clientOrNull;
    if (client == null) {
      return FallbackSeedData.doctors;
    }
    try {
      final response = await client
          .from('doctors')
          .select()
          .order('is_featured', ascending: false)
          .order('rating', ascending: false);
      final list = (response as List<dynamic>)
          .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return list.isEmpty ? FallbackSeedData.doctors : list;
    } catch (_) {
      return FallbackSeedData.doctors;
    }
  }

  Future<DoctorModel?> fetchDoctorById(String id) async {
    final all = await fetchDoctors();
    for (final d in all) {
      if (d.id == id) return d;
    }
    return all.isNotEmpty ? all.first : null;
  }
}
