import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';

String money(int amount) {
  final s = amount.toString();
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

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Color statusColor(OrderStatus s) => switch (s) {
      OrderStatus.paid => Colors.blue,
      OrderStatus.processing => Colors.orange,
      OrderStatus.readyForDelivery => Colors.purple,
      OrderStatus.courierAccepted ||
      OrderStatus.scheduled ||
      OrderStatus.onTheWay =>
        Colors.teal,
      OrderStatus.delivered => Colors.green,
      OrderStatus.cancelled => Colors.red,
    };

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.label,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Барааны зураг оронд категорийн дүрс бүхий өнгөт хайрцаг.
class ProductThumb extends StatelessWidget {
  const ProductThumb(this.product, {super.key, this.size = 56});

  final Product product;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (product.category) {
      'Электрон' => (Icons.devices_other, Colors.indigo),
      'Хувцас' => (Icons.checkroom, Colors.pink),
      'Ном' => (Icons.menu_book, Colors.brown),
      _ => (Icons.shopping_bag, Colors.teal),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
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
            ? Icons.star
            : value > i
                ? Icons.star_half
                : Icons.star_border;
        return Icon(icon, size: size, color: Colors.amber);
      }),
    );
  }
}

class PriceText extends StatelessWidget {
  const PriceText(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (product.discountPercent == 0) {
      return Text(money(product.price),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold));
    }
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(money(product.finalPrice),
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.red.shade700)),
        Text(money(product.price),
            style: const TextStyle(
                decoration: TextDecoration.lineThrough, color: Colors.grey)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(6)),
          child: Text('-${product.discountPercent}%',
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ),
      ],
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile(
      {super.key, required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Багцгүй, энгийн хэвтээ баганан график.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.data, this.format});

  final Map<String, int> data;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Өгөгдөл алга'),
      );
    }
    final maxV = data.values.reduce((a, b) => a > b ? a : b);
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: data.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
                  Text(format?.call(e.value) ?? '${e.value}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: maxV == 0 ? 0 : e.value / maxV,
                  minHeight: 10,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
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
      appBar: AppBar(title: Text(title)),
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
                      return Align(
                        alignment:
                            mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: mine
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(m.text,
                              style: TextStyle(
                                  color: mine ? scheme.onPrimary : null)),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Мессеж бичих...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(app),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _send(app),
                    icon: const Icon(Icons.send),
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
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Гарах',
      icon: const Icon(Icons.logout),
      onPressed: () => AppScope.read(context).logout(),
    );
  }
}
