import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';

/// Админ актор: Тайлан харах, Бүтээгдэхүүн хянах, Дэлгүүр баталгаажуулах,
/// Гомдол шийдвэрлэх.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final openComplaints =
        app.complaints.where((c) => c.status == ComplaintStatus.open).length;
    final pendingProducts = app.products.where((p) => !p.approved).length;
    final pendingStores = app.stores.where((s) => !s.verified).length;
    const pages = [
      AdminReportTab(),
      ProductReviewTab(),
      StoreVerifyTab(),
      ComplaintsTab(),
    ];
    Widget badge(int n, IconData icon) => Badge(
        isLabelVisible: n > 0, label: Text('$n'), child: Icon(icon));
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.insights), label: 'Тайлан'),
          NavigationDestination(
              icon: badge(pendingProducts, Icons.fact_check_outlined),
              label: 'Бүтээгдэхүүн'),
          NavigationDestination(
              icon: badge(pendingStores, Icons.verified_outlined),
              label: 'Дэлгүүр'),
          NavigationDestination(
              icon: badge(openComplaints, Icons.report_outlined),
              label: 'Гомдол'),
        ],
      ),
    );
  }
}

// ======================= Тайлан харах =======================

class AdminReportTab extends StatelessWidget {
  const AdminReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final byStatus = <String, int>{};
    for (final o in app.orders) {
      byStatus[o.status.label] = (byStatus[o.status.label] ?? 0) + 1;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Системийн тайлан'),
        actions: const [LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              StatTile(
                  label: 'Нийт борлуулалт',
                  value: money(app.totalRevenue),
                  icon: Icons.payments_outlined),
              StatTile(
                  label: 'Захиалга',
                  value: '${app.orders.length}',
                  icon: Icons.receipt_long),
              StatTile(
                  label: 'Худалдан авагч',
                  value: '${app.usersByRole(UserRole.buyer).length}',
                  icon: Icons.people_outline),
              StatTile(
                  label: 'Дэлгүүр',
                  value: '${app.stores.length}',
                  icon: Icons.store_outlined),
            ],
          ),
          const SizedBox(height: 12),
          _section(context, 'Дэлгүүрээр борлуулалт',
              SimpleBarChart(data: app.revenueByStore(), format: money)),
          const SizedBox(height: 12),
          _section(context, 'Захиалгын төлөв', SimpleBarChart(data: byStatus)),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      );
}

// ======================= Бүтээгдэхүүн хянах =======================

class ProductReviewTab extends StatelessWidget {
  const ProductReviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = [...app.products]
      ..sort((a, b) => (a.approved ? 1 : 0).compareTo(b.approved ? 1 : 0));
    return Scaffold(
      appBar: AppBar(title: const Text('Бүтээгдэхүүн хянах')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final p in items)
            Card(
              child: SwitchListTile(
                secondary: ProductThumb(p, size: 44),
                title: Text(p.name),
                subtitle: Text(
                    '${app.storeById(p.storeId).name} · ${money(p.finalPrice)}\n'
                    '${p.approved ? 'Зөвшөөрсөн' : 'Хяналт хүлээж буй / нуусан'}'),
                isThreeLine: true,
                value: p.approved,
                onChanged: (v) {
                  app.setProductApproved(p, v);
                  toast(context,
                      v ? '${p.name} зөвшөөрөгдлөө' : '${p.name} нуугдлаа');
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ======================= Дэлгүүр баталгаажуулах =======================

class StoreVerifyTab extends StatelessWidget {
  const StoreVerifyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Дэлгүүр баталгаажуулах')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final s in app.stores)
            Card(
              child: ListTile(
                leading: Icon(s.verified ? Icons.verified : Icons.hourglass_top,
                    color: s.verified ? Colors.green : Colors.orange),
                title: Text(s.name),
                subtitle: Text(
                    '${s.category} · Эзэмшигч: ${app.userById(s.ownerId)?.name ?? '-'}\n${s.description}'),
                isThreeLine: true,
                trailing: s.verified
                    ? TextButton(
                        onPressed: () => app.setStoreVerified(s, false),
                        child: const Text('Цуцлах'))
                    : FilledButton(
                        onPressed: () {
                          app.setStoreVerified(s, true);
                          toast(context, '${s.name} баталгаажлаа');
                        },
                        child: const Text('Батлах')),
              ),
            ),
        ],
      ),
    );
  }
}

// ======================= Гомдол шийдвэрлэх =======================

class ComplaintsTab extends StatelessWidget {
  const ComplaintsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Гомдол шийдвэрлэх')),
      body: app.complaints.isEmpty
          ? const EmptyState(icon: Icons.task_alt, text: 'Гомдол алга')
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final c in app.complaints)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(
                                  '${c.orderId} · ${app.userById(c.buyerId)?.name ?? ''}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            Chip(
                              label: Text(c.status == ComplaintStatus.open
                                  ? 'Нээлттэй'
                                  : 'Шийдвэрлэсэн'),
                              backgroundColor: c.status == ComplaintStatus.open
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,
                            ),
                          ]),
                          Text(shortDate(c.createdAt),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(c.text),
                          if (c.resolution != null) ...[
                            const SizedBox(height: 6),
                            Text('Шийдвэр: ${c.resolution}',
                                style: const TextStyle(color: Colors.green)),
                          ],
                          if (c.status == ComplaintStatus.open)
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: () => _resolve(context, c),
                                child: const Text('Шийдвэрлэх'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _resolve(BuildContext context, Complaint c) async {
    final ctrl = TextEditingController(
        text: 'Дэлгүүртэй холбогдож, барааг солиулахаар шийдвэрлэлээ.');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Гомдлын шийдвэр'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Болих')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Хадгалах')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).resolveComplaint(c, ctrl.text.trim());
      toast(context, 'Гомдол шийдвэрлэгдлээ');
    }
    ctrl.dispose();
  }
}
