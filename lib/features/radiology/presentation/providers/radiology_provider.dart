import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/radiology_repository.dart';
import '../../domain/radiology_model.dart';

final radiologyRepositoryProvider = Provider<RadiologyRepository>((ref) {
  return RadiologyRepository();
});

final radiologyCentersProvider =
    FutureProvider<List<RadiologyCenterModel>>((ref) async {
  return ref.watch(radiologyRepositoryProvider).fetchCentersWithScans();
});

final radiologyCenterByIdProvider =
    FutureProvider.family<RadiologyCenterModel?, String>((ref, id) async {
  return ref.watch(radiologyRepositoryProvider).fetchCenterById(id);
});
