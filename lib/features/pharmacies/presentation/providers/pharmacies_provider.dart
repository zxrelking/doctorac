import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/pharmacies_repository.dart';
import '../../domain/pharmacy_model.dart';

final pharmaciesRepositoryProvider = Provider<PharmaciesRepository>((ref) {
  return PharmaciesRepository();
});

final pharmaciesListProvider =
    FutureProvider<List<PharmacyModel>>((ref) async {
  return ref.watch(pharmaciesRepositoryProvider).fetchPharmacies();
});

final pharmacyByIdProvider =
    FutureProvider.family<PharmacyModel?, String>((ref, id) async {
  return ref.watch(pharmaciesRepositoryProvider).fetchPharmacyById(id);
});
