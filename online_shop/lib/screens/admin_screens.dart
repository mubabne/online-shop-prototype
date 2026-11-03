import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/animations.dart';
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
    Widget badge(int n, IconData icon) => BumpOnChange(
          value: n,
          child: Badge(
              isLabelVisible: n > 0, label: Text('$n'), child: Icon(icon)),
        );
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.insights_rounded), label: 'Тайлан'),
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
    final pending = app.products.where((p) => !p.approved).length +
        app.stores.where((s) => !s.verified).length +
        app.complaints.where((c) => c.status == ComplaintStatus.open).length;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        GradientHeader(
          subtitle: 'Админы самбар',
          title: 'Системийн тайлан',
          colors: AppColors.role(UserRole.admin),
          icon: Icons.admin_panel_settings_rounded,
          trailing: const LogoutButton(color: Colors.white),
          bottom: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.notifications_active_rounded,
                  color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pending == 0
                      ? 'Хянах зүйл алга. Бүх зүйл хэвийн!'
                      : '$pending зүйл таны хяналтыг хүлээж байна',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StatGrid(children: [
                StatTile(
                    label: 'Нийт борлуулалт',
                    value: app.totalRevenue,
                    format: money,
                    icon: Icons.payments_rounded,
                    colors: AppColors.role(UserRole.merchant)),
                StatTile(
                    label: 'Захиалга',
                    value: app.orders.length,
                    icon: Icons.receipt_long_rounded,
                    colors: AppColors.role(UserRole.buyer)),
                StatTile(
                    label: 'Худалдан авагч',
                    value: app.usersByRole(UserRole.buyer).length,
                    icon: Icons.people_alt_rounded,
                    colors: AppColors.role(UserRole.courier)),
                StatTile(
                    label: 'Дэлгүүр',
                    value: app.stores.length,
                    icon: Icons.storefront_rounded,
                    colors: const [Color(0xFFFF6F91), Color(0xFFFF9671)]),
              ]),
              const SizedBox(height: 8),
              FadeSlideIn(
                index: 4,
                child: SectionCard(
                  title: 'Дэлгүүрээр борлуулалт',
                  icon: Icons.bar_chart_rounded,
                  child:
                      SimpleBarChart(data: app.revenueByStore(), format: money),
                ),
              ),
              FadeSlideIn(
                index: 5,
                child: SectionCard(
                  title: 'Захиалгын төлөв',
                  icon: Icons.donut_large_rounded,
                  child: SimpleBarChart(data: byStatus),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          for (final (i, p) in items.indexed)
            FadeSlideIn(
              index: i,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ProductThumb(p, size: 54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(
                                '${app.storeById(p.storeId).name} · ${money(p.finalPrice)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _Tag(
                                key: ValueKey(p.approved),
                                text: p.approved
                                    ? 'Зөвшөөрсөн'
                                    : 'Хяналт хүлээж буй',
                                color: p.approved ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: p.approved,
                        onChanged: (v) {
                          app.setProductApproved(p, v);
                          toast(context,
                              v ? '${p.name} зөвшөөрөгдлөө' : '${p.name} нуугдлаа',
                              icon: v
                                  ? Icons.check_circle_rounded
                                  : Icons.visibility_off_rounded);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w700)),
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          for (final (i, s) in app.stores.indexed)
            FadeSlideIn(
              index: i,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: AppColors.category(s.category).$2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(AppColors.category(s.category).$1,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Flexible(
                                child: Text(s.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 4),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (c, a) =>
                                    ScaleTransition(scale: a, child: c),
                                child: Icon(
                                  s.verified
                                      ? Icons.verified_rounded
                                      : Icons.hourglass_top_rounded,
                                  key: ValueKey(s.verified),
                                  size: 18,
                                  color: s.verified
                                      ? const Color(0xFF4F7CFF)
                                      : Colors.orange,
                                ),
                              ),
                            ]),
                            Text(
                                '${s.category} · ${app.userById(s.ownerId)?.name ?? '-'}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            Text(s.description,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      s.verified
                          ? TextButton(
                              onPressed: () => app.setStoreVerified(s, false),
                              child: const Text('Цуцлах'))
                          : FilledButton(
                              onPressed: () {
                                app.setStoreVerified(s, true);
                                toast(context, '${s.name} баталгаажлаа',
                                    icon: Icons.verified_rounded);
                              },
                              child: const Text('Батлах')),
                    ],
                  ),
                ),
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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                for (final (i, c) in app.complaints.indexed)
                  FadeSlideIn(
                    index: i,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              CircleAvatar(
                                backgroundColor: (c.status ==
                                            ComplaintStatus.open
                                        ? Colors.orange
                                        : Colors.green)
                                    .withValues(alpha: 0.15),
                                child: Icon(
                                    c.status == ComplaintStatus.open
                                        ? Icons.report_rounded
                                        : Icons.task_alt_rounded,
                                    color: c.status == ComplaintStatus.open
                                        ? Colors.orange
                                        : Colors.green),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${c.orderId} · ${app.userById(c.buyerId)?.name ?? ''}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    Text(shortDate(c.createdAt),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                              ),
                              _Tag(
                                text: c.status == ComplaintStatus.open
                                    ? 'Нээлттэй'
                                    : 'Шийдвэрлэсэн',
                                color: c.status == ComplaintStatus.open
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ]),
                            const SizedBox(height: 10),
                            Text(c.text),
                            if (c.resolution != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Шийдвэр: ${c.resolution}',
                                    style:
                                        const TextStyle(color: Colors.green)),
                              ),
                            ],
                            if (c.status == ComplaintStatus.open) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton.icon(
                                  onPressed: () => _resolve(context, c),
                                  icon: const Icon(Icons.gavel_rounded),
                                  label: const Text('Шийдвэрлэх'),
                                ),
                              ),
                            ],
                          ],
                        ),
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
        content: TextField(controller: ctrl, maxLines: 3),
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
      toast(context, 'Гомдол шийдвэрлэгдлээ', icon: Icons.gavel_rounded);
    }
    ctrl.dispose();
  }
}
