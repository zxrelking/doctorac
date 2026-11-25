import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/orders_repository.dart';
import '../../domain/order_model.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository();
});

class OrdersNotifier extends AsyncNotifier<List<OrderModel>> {
  @override
  Future<List<OrderModel>> build() async {
    return ref.watch(ordersRepositoryProvider).fetchUserOrders();
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    final repo = ref.read(ordersRepositoryProvider);
    final created = await repo.createOrder(order);
    final current = state.valueOrNull ?? [];
    state = AsyncData([created, ...current]);
    return created;
  }

  Future<void> cancelOrder(String orderId) async {
    final repo = ref.read(ordersRepositoryProvider);
    await repo.cancelOrder(orderId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current
          .map((o) => o.id == orderId ? o.copyWith(status: 'cancelled') : o)
          .toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ordersRepositoryProvider).fetchUserOrders(),
    );
  }
}

final ordersProvider = AsyncNotifierProvider<OrdersNotifier, List<OrderModel>>(
  OrdersNotifier.new,
);
