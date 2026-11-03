import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';

/// Хүргэлт актор: Хүргэлт хүлээн авах, хуваарилах, төлөв шинэчлэх,
/// баталгаажуулах.
class CourierHome extends StatefulWidget {
  const CourierHome({super.key});

  @override
  State<CourierHome> createState() => _CourierHomeState();
}

class _CourierHomeState extends State<CourierHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final available = app.availableDeliveries.length;
    return Scaffold(
      body: _tab == 0 ? const AvailableDeliveriesTab() : const MyDeliveriesTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: available > 0,
              label: Text('$available'),
              child: const Icon(Icons.move_to_inbox_outlined),
            ),
            label: 'Шинэ хүргэлт',
          ),
          const NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              label: 'Миний хүргэлт'),
        ],
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary(this.order);

  final Order order;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final buyer = app.userById(order.buyerId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(order.id,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          StatusChip(order.status),
        ]),
        const SizedBox(height: 6),
        _line(Icons.store_outlined, 'Авах: ${app.storeById(order.storeId).name}'),
        _line(Icons.place_outlined, 'Хүргэх: ${order.address}'),
        _line(Icons.person_outline,
            '${buyer?.name ?? ''} · ${buyer?.phone ?? ''}'),
        _line(Icons.inventory_2_outlined,
            order.lines.map((l) => '${l.productName} × ${l.quantity}').join(', ')),
        if (order.deliverySlot != null)
          _line(Icons.schedule, 'Хуваарь: ${order.deliverySlot}'),
      ],
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

// ======================= Хүргэлт хүлээн авах =======================

class AvailableDeliveriesTab extends StatelessWidget {
  const AvailableDeliveriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final orders = app.availableDeliveries;
    return Scaffold(
      appBar: AppBar(
        title: Text('Сайн байна уу, ${app.currentUser!.name}'),
        actions: const [LogoutButton()],
      ),
      body: orders.isEmpty
          ? const EmptyState(
              icon: Icons.inbox_outlined,
              text: 'Хүргэлтэд бэлэн захиалга алга.\n'
                  'Дэлгүүр захиалгыг "Хүргэлтэд шилжүүлэх" үед энд гарна.')
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final o in orders)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _OrderSummary(o),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: () {
                              app.acceptDelivery(o);
                              toast(context, '${o.id} хүргэлтийг хүлээн авлаа');
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Хүргэлт хүлээн авах'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ======================= Хуваарилах, төлөв шинэчлэх, баталгаажуулах =======================

class MyDeliveriesTab extends StatelessWidget {
  const MyDeliveriesTab({super.key});

  static const slots = [
    'Өнөөдөр 10:00–12:00',
    'Өнөөдөр 14:00–16:00',
    'Өнөөдөр 18:00–20:00',
    'Маргааш 10:00–12:00',
    'Маргааш 14:00–16:00',
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final mine = app.deliveriesOf(app.currentUser!.id);
    final active =
        mine.where((o) => o.status != OrderStatus.delivered).toList();
    final done = mine.where((o) => o.status == OrderStatus.delivered).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Миний хүргэлт')),
      body: mine.isEmpty
          ? const EmptyState(
              icon: Icons.local_shipping_outlined,
              text: 'Хүлээн авсан хүргэлт алга')
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (active.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text('Идэвхтэй',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                for (final o in active)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _OrderSummary(o),
                          const SizedBox(height: 8),
                          ..._actions(context, app, o),
                        ],
                      ),
                    ),
                  ),
                if (done.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 4),
                    child: Text('Хүргэгдсэн',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                for (final o in done)
                  Card(
                    child: ListTile(
                      leading:
                          const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(o.id),
                      subtitle: Text(
                          '${o.address}\nХүлээн авсан: ${o.receivedBy ?? '-'}'),
                      isThreeLine: true,
                    ),
                  ),
              ],
            ),
    );
  }

  List<Widget> _actions(BuildContext context, AppState app, Order o) {
    return switch (o.status) {
      OrderStatus.courierAccepted => [
          FilledButton.icon(
            onPressed: () => _schedule(context, o),
            icon: const Icon(Icons.schedule),
            label: const Text('Хүргэлт хуваарилах'),
          ),
        ],
      OrderStatus.scheduled => [
          FilledButton.icon(
            onPressed: () {
              app.setOrderStatus(o, OrderStatus.onTheWay);
              toast(context, 'Төлөв шинэчлэгдлээ: Замд явж байна');
            },
            icon: const Icon(Icons.directions_bike),
            label: const Text('Төлөв шинэчлэх: Замд гарсан'),
          ),
          TextButton(
            onPressed: () => _schedule(context, o),
            child: const Text('Хуваарь өөрчлөх'),
          ),
        ],
      OrderStatus.onTheWay => [
          FilledButton.icon(
            onPressed: () => _confirm(context, o),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Хүргэлт баталгаажуулах'),
          ),
        ],
      _ => const [],
    };
  }

  Future<void> _schedule(BuildContext context, Order o) async {
    final slot = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Хүргэлтийн цаг сонгох',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final s in slots)
              ListTile(
                leading: Icon(
                    s == o.deliverySlot ? Icons.check_circle : Icons.schedule),
                title: Text(s),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (slot != null && context.mounted) {
      AppScope.read(context).scheduleDelivery(o, slot);
      toast(context, 'Хуваарилагдлаа: $slot');
    }
  }

  Future<void> _confirm(BuildContext context, Order o) async {
    final ctrl = TextEditingController(
        text: AppScope.read(context).userById(o.buyerId)?.name ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Хүргэлт баталгаажуулах'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${o.id} · ${money(o.total)}'),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                  labelText: 'Хүлээн авсан хүний нэр',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Болих')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Баталгаажуулах')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty && context.mounted) {
      AppScope.read(context).confirmDelivery(o, ctrl.text.trim());
      toast(context, 'Хүргэлт баталгаажлаа');
    }
    ctrl.dispose();
  }
}
