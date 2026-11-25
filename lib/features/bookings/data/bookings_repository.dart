import '../../../core/config/supabase_config.dart';
import '../../../core/utils/arabic_date_formatter.dart';
import '../domain/booking_model.dart';

class BookingsRepository {
  Future<List<BookingModel>> fetchUserBookings() async {
    final client = SupabaseConfig.clientOrNull;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return const [];
    }
    final response = await client
        .from('bookings')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> createBooking(BookingModel booking) async {
    final client = SupabaseConfig.clientOrNull;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      throw Exception('يرجى تسجيل الدخول أولاً لإتمام الحجز.');
    }
    final inserted = await client
        .from('bookings')
        .insert(booking.toInsertJson(userId))
        .select()
        .single();
    return BookingModel.fromJson(inserted);
  }

  Future<void> cancelBooking(String bookingId) async {
    final client = SupabaseConfig.clientOrNull;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    await client
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId)
        .eq('user_id', userId);
  }

  Future<void> rescheduleBooking({
    required String bookingId,
    required DateTime newDate,
    required String newTime,
  }) async {
    final client = SupabaseConfig.clientOrNull;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    await client
        .from('bookings')
        .update({
          'appointment_date': ArabicDateFormatter.toIsoDate(newDate),
          'appointment_time': newTime,
          'status': 'confirmed',
        })
        .eq('id', bookingId)
        .eq('user_id', userId);
  }
}
