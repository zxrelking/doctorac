import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/bookings_repository.dart';
import '../../domain/booking_model.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return BookingsRepository();
});

class BookingsNotifier extends AsyncNotifier<List<BookingModel>> {
  @override
  Future<List<BookingModel>> build() async {
    return ref.watch(bookingsRepositoryProvider).fetchUserBookings();
  }

  Future<BookingModel> addBooking(BookingModel booking) async {
    final repo = ref.read(bookingsRepositoryProvider);
    final created = await repo.createBooking(booking);
    final current = state.valueOrNull ?? [];
    state = AsyncData([created, ...current]);
    return created;
  }

  Future<void> cancelBooking(String bookingId) async {
    final repo = ref.read(bookingsRepositoryProvider);
    await repo.cancelBooking(bookingId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current
          .map((b) => b.id == bookingId ? b.copyWith(status: 'cancelled') : b)
          .toList(),
    );
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required String newTime,
  }) async {
    final repo = ref.read(bookingsRepositoryProvider);
    await repo.rescheduleBooking(
      bookingId: bookingId,
      newDate: newDate,
      newTime: newTime,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current
          .map(
            (b) => b.id == bookingId
                ? b.copyWith(
                    appointmentDate: newDate,
                    appointmentTime: newTime,
                    status: 'confirmed',
                  )
                : b,
          )
          .toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(bookingsRepositoryProvider).fetchUserBookings(),
    );
  }
}

final bookingsProvider =
    AsyncNotifierProvider<BookingsNotifier, List<BookingModel>>(
  BookingsNotifier.new,
);
