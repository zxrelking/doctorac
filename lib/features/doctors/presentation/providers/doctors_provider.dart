import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/doctors_repository.dart';
import '../../domain/doctor_model.dart';

final doctorsRepositoryProvider = Provider<DoctorsRepository>((ref) {
  return DoctorsRepository();
});

final doctorsListProvider = FutureProvider<List<DoctorModel>>((ref) async {
  return ref.watch(doctorsRepositoryProvider).fetchDoctors();
});

final doctorByIdProvider =
    FutureProvider.family<DoctorModel?, String>((ref, id) async {
  return ref.watch(doctorsRepositoryProvider).fetchDoctorById(id);
});
