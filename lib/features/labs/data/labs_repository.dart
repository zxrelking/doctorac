import '../../../core/config/supabase_config.dart';
import '../../../core/data/fallback_seed_data.dart';
import '../domain/lab_model.dart';

class LabsRepository {
  Future<List<LabModel>> fetchLabsWithTests() async {
    final client = SupabaseConfig.clientOrNull;
    if (client == null) {
      return FallbackSeedData.labs;
    }
    try {
      final response = await client
          .from('labs')
          .select('*, lab_tests(*)')
          .order('rating', ascending: false);
      final list = (response as List<dynamic>)
          .map((e) => LabModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return list.isEmpty ? FallbackSeedData.labs : list;
    } catch (_) {
      return FallbackSeedData.labs;
    }
  }

  Future<LabModel?> fetchLabById(String id) async {
    final labs = await fetchLabsWithTests();
    for (final lab in labs) {
      if (lab.id == id) return lab;
    }
    return labs.isNotEmpty ? labs.first : null;
  }
}
