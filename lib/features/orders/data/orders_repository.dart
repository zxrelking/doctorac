import '../../../core/config/supabase_config.dart';
import '../domain/order_model.dart';

class OrdersRepository {
  Future<List<OrderModel>> fetchUserOrders() async {
    final client = SupabaseConfig.clientOrNull;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return const [];
    }
    final response = await client
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    final client = SupabaseConfig.clientOrNull;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      throw Exception('يرجى تسجيل الدخول أولاً لإرسال الطلب.');
    }
    final inserted = await client
        .from('orders')
        .insert(order.toInsertJson(userId))
        .select()
        .single();
    return OrderModel.fromJson(inserted);
  }

  Future<void> cancelOrder(String orderId) async {
    final client = SupabaseConfig.clientOrNull;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    await client
        .from('orders')
        .update({'status': 'cancelled'})
        .eq('id', orderId)
        .eq('user_id', userId);
  }
}
