import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/labs_repository.dart';
import '../../domain/lab_model.dart';

final labsRepositoryProvider = Provider<LabsRepository>((ref) {
  return LabsRepository();
});

final labsListProvider = FutureProvider<List<LabModel>>((ref) async {
  return ref.watch(labsRepositoryProvider).fetchLabsWithTests();
});

final labByIdProvider =
    FutureProvider.family<LabModel?, String>((ref, id) async {
  return ref.watch(labsRepositoryProvider).fetchLabById(id);
});
