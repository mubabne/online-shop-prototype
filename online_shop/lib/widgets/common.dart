import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'animations.dart';

String money(num amount) {
  final s = amount.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return '$buf төг';
}

String shortDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

void toast(BuildContext context, String text, {IconData? icon}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon ?? Icons.check_circle_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ]),
    ));
}

Color statusColor(OrderStatus s) => switch (s) {
      OrderStatus.paid => const Color(0xFF4F7CFF),
      OrderStatus.processing => const Color(0xFFFF9F43),
      OrderStatus.readyForDelivery => const Color(0xFF8E5CF7),
      OrderStatus.courierAccepted ||
      OrderStatus.scheduled ||
      OrderStatus.onTheWay =>
        const Color(0xFF00B894),
      OrderStatus.delivered => const Color(0xFF2ECC71),
      OrderStatus.cancelled => const Color(0xFFFF5E57),
    };

IconData statusIcon(OrderStatus s) => switch (s) {
      OrderStatus.paid => Icons.payments_rounded,
      OrderStatus.processing => Icons.inventory_rounded,
      OrderStatus.readyForDelivery => Icons.outbox_rounded,
      OrderStatus.courierAccepted => Icons.person_pin_circle_rounded,
      OrderStatus.scheduled => Icons.schedule_rounded,
      OrderStatus.onTheWay => Icons.delivery_dining_rounded,
      OrderStatus.delivered => Icons.verified_rounded,
      OrderStatus.cancelled => Icons.cancel_rounded,
    };

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 14, color: c),
          const SizedBox(width: 4),
          Text(status.label,
              style: TextStyle(
                  color: c, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Барааны зургийн оронд ангиллын градиент, дүрс бүхий хайрцаг.
/// [heroTag] өгвөл дэлгэц хооронд Hero анимэйшнээр шилжинэ.
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.product,
      {super.key, this.size = 56, this.height, this.heroTag, this.radius});

  final Product product;
  final double size;
  final double? height;
  final Object? heroTag;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final (icon, colors) = AppColors.category(product.category);
    final h = height ?? size;
    final s = size < h ? size : h;
    final box = Container(
      width: size,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius ?? s * 0.28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -s * 0.18,
            top: -s * 0.18,
            child: Container(
              width: s * 0.65,
              height: s * 0.65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            left: -s * 0.1,
            bottom: -s * 0.2,
            child: Container(
              width: s * 0.5,
              height: s * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Center(child: Icon(icon, color: Colors.white, size: s * 0.46)),
        ],
      ),
    );
    return heroTag == null ? box : Hero(tag: heroTag!, child: box);
  }
}

class Stars extends StatelessWidget {
  const Stars(this.value, {super.key, this.size = 16});

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final icon = value >= i + 1
            ? Icons.star_rounded
            : value > i
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        return Icon(icon, size: size, color: const Color(0xFFFFB300));
      }),
    );
  }
}

class PriceText extends StatelessWidget {
  const PriceText(this.product, {super.key, this.large = false});

  final Product product;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = large ? theme.textTheme.headlineSmall : theme.textTheme.titleMedium;
    if (product.discountPercent == 0) {
      return Text(money(product.price),
          style: base?.copyWith(fontWeight: FontWeight.w800));
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(money(product.finalPrice),
            style: base?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.accent)),
        Text(money(product.price),
            style: TextStyle(
                fontSize: large ? 14 : 11,
                decoration: TextDecoration.lineThrough,
                color: Colors.grey)),
      ],
    );
  }
}

class DiscountBadge extends StatelessWidget {
  const DiscountBadge(this.percent, {super.key});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFF5E62), Color(0xFFFF9966)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('-$percent%',
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}

/// Тоо нь тоологдож гарах статистикийн хавтан.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.format,
    this.colors = const [Color(0xFF5B4CF0), Color(0xFF8E5CF7)],
  });

  final String label;
  final num value;
  final IconData icon;
  final String Function(num)? format;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: CountUpText(
                    value: value,
                    format: format,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 2 баганатай статистикийн хүснэгт.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 4,
      children: [
        for (var i = 0; i < children.length; i++)
          FadeSlideIn(index: i, child: children[i]),
      ],
    );
  }
}

/// Багцгүй, анимэйшнтэй хэвтээ баганан график.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.data, this.format});

  final Map<String, int> data;
  final String Function(int)? format;

  static const _palette = [
    [Color(0xFF5B4CF0), Color(0xFF8E5CF7)],
    [Color(0xFFFF7A59), Color(0xFFFFB86B)],
    [Color(0xFF00B894), Color(0xFF55EFC4)],
    [Color(0xFF4F7CFF), Color(0xFF74B9FF)],
    [Color(0xFFFF6F91), Color(0xFFFF9671)],
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Өгөгдөл алга'),
      );
    }
    final maxV = data.values.reduce((a, b) => a > b ? a : b);
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    final entries = data.entries.toList();
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(entries[i].key,
                            overflow: TextOverflow.ellipsis)),
                    Text(format?.call(entries[i].value) ?? '${entries[i].value}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: track,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                        begin: 0,
                        end: maxV == 0 ? 0 : entries[i].value / maxV),
                    duration: Duration(milliseconds: 800 + i * 120),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: _palette[i % _palette.length]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Гарчиг + агуулга бүхий карт.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child, this.icon});

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Дүр бүрийн өнгөтэй, градиент толгой хэсэг (dashboard-уудад).
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.icon,
    this.trailing,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData? icon;
  final Widget? trailing;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subtitle,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85))),
                        Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (bottom != null) ...[const SizedBox(height: 16), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: scheme.primary),
              ),
              const SizedBox(height: 16),
              Text(text,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Use case: Дэлгүүртэй холбогдох (худалдан авагч) / Хэрэглэгчтэй холбогдох (дэлгүүр)
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.buyerId,
    required this.storeId,
    required this.asBuyer,
  });

  final String buyerId;
  final String storeId;
  final bool asBuyer;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send(AppState app) {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    app.sendMessage(widget.buyerId, widget.storeId, text,
        fromBuyer: widget.asBuyer);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final messages = app.chatOf(widget.buyerId, widget.storeId);
    final title = widget.asBuyer
        ? app.storeById(widget.storeId).name
        : app.userById(widget.buyerId)?.name ?? 'Хэрэглэгч';
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Icon(widget.asBuyer ? Icons.storefront : Icons.person,
                color: scheme.primary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17)),
              const Text('Онлайн',
                  style: TextStyle(fontSize: 12, color: Colors.green)),
            ],
          ),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    text: 'Мессеж алга. Асуултаа бичээрэй.')
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final m = messages[i];
                      final mine = m.fromBuyer == widget.asBuyer;
                      return FadeSlideIn(
                        key: ValueKey(m),
                        offset: Offset(mine ? 0.2 : -0.2, 0),
                        child: Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              gradient: mine ? AppColors.brandGradient : null,
                              color: mine
                                  ? null
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(mine ? 18 : 4),
                                bottomRight: Radius.circular(mine ? 4 : 18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(m.text,
                                    style: TextStyle(
                                        color: mine ? Colors.white : null)),
                                const SizedBox(height: 2),
                                Text(
                                  '${m.at.hour.toString().padLeft(2, '0')}:${m.at.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: mine
                                          ? Colors.white70
                                          : scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Мессеж бичих...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(app),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _send(app),
                    icon: const Icon(Icons.send_rounded),
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

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Гарах',
      color: color,
      icon: const Icon(Icons.logout_rounded),
      onPressed: () => AppScope.read(context).logout(),
    );
  }
}
