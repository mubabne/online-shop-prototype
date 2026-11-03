import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/animations.dart';
import '../widgets/common.dart';
import 'buyer_screens.dart' show OrderCard;

/// Дэлгүүр /Merch актор: дэлгүүр, бараа, үнэ, захиалга, тайлан, чат.
class MerchantHome extends StatefulWidget {
  const MerchantHome({super.key});

  @override
  State<MerchantHome> createState() => _MerchantHomeState();
}

class _MerchantHomeState extends State<MerchantHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.storeOfOwner(app.currentUser!.id);
    if (store == null) return const StoreFormScreen();

    final pages = [
      StoreInfoTab(store: store),
      MerchantProductsTab(store: store),
      MerchantOrdersTab(store: store),
      SalesReportTab(store: store),
      CustomerChatsTab(store: store),
    ];
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.store_outlined), label: 'Дэлгүүр'),
          const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined), label: 'Бараа'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: app
                  .ordersOfStore(store.id)
                  .any((o) => o.status == OrderStatus.paid),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            label: 'Захиалга',
          ),
          const NavigationDestination(
              icon: Icon(Icons.bar_chart), label: 'Тайлан'),
          const NavigationDestination(
              icon: Icon(Icons.chat_outlined), label: 'Чат'),
        ],
      ),
    );
  }
}

// ======================= Дэлгүүр үүсгэх, хянах =======================

class StoreFormScreen extends StatefulWidget {
  const StoreFormScreen({super.key, this.store});

  final Store? store;

  @override
  State<StoreFormScreen> createState() => _StoreFormScreenState();
}

class _StoreFormScreenState extends State<StoreFormScreen> {
  late final _name = TextEditingController(text: widget.store?.name);
  late final _desc = TextEditingController(text: widget.store?.description);
  late final _cat = TextEditingController(text: widget.store?.category);

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _cat.dispose();
    super.dispose();
  }

  void _save() {
    final app = AppScope.read(context);
    if (_name.text.trim().isEmpty) {
      toast(context, 'Дэлгүүрийн нэр оруулна уу');
      return;
    }
    if (widget.store == null) {
      app.createStore(
          name: _name.text.trim(),
          description: _desc.text.trim(),
          category: _cat.text.trim());
      toast(context, 'Дэлгүүр үүслээ. Админ баталгаажуулахыг хүлээнэ үү.');
    } else {
      app.updateStore(widget.store!,
          name: _name.text.trim(),
          description: _desc.text.trim(),
          category: _cat.text.trim());
      Navigator.pop(context);
      toast(context, 'Хадгалагдлаа');
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = widget.store == null;
    return Scaffold(
      appBar: AppBar(
        title: Text(creating ? 'Дэлгүүр үүсгэх' : 'Дэлгүүр засах'),
        actions: [if (creating) const LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Дэлгүүрийн нэр')),
          const SizedBox(height: 12),
          TextField(
              controller: _cat,
              decoration: const InputDecoration(
                  labelText: 'Ангилал')),
          const SizedBox(height: 12),
          TextField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Тайлбар')),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Хадгалах')),
        ],
      ),
    );
  }
}

class StoreInfoTab extends StatelessWidget {
  const StoreInfoTab({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final orders = app.ordersOfStore(store.id);
    final active = orders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled)
        .length;
    final statusColor = store.verified ? Colors.green : Colors.orange;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        GradientHeader(
          subtitle: 'Миний дэлгүүр',
          title: store.name,
          colors: AppColors.role(UserRole.merchant),
          icon: Icons.storefront_rounded,
          trailing: const LogoutButton(color: Colors.white),
          bottom: Text(
            '${store.category} · ${store.description}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                child: Card(
                  color: statusColor.withValues(alpha: 0.12),
                  child: ListTile(
                    leading: Icon(
                        store.verified
                            ? Icons.verified_rounded
                            : Icons.hourglass_top_rounded,
                        color: statusColor),
                    title: Text(
                        store.verified
                            ? 'Баталгаажсан дэлгүүр'
                            : 'Админы баталгаажуулалт хүлээж байна',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(store.verified
                        ? 'Таны бараа хэрэглэгчдэд харагдаж байна.'
                        : 'Баталгаажих хүртэл бараа хайлтад гарахгүй.'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              StatGrid(children: [
                StatTile(
                    label: 'Бараа',
                    value:
                        app.productsOfStore(store.id, onlyVisible: false).length,
                    icon: Icons.inventory_2_rounded,
                    colors: AppColors.role(UserRole.merchant)),
                StatTile(
                    label: 'Идэвхтэй захиалга',
                    value: active,
                    icon: Icons.pending_actions_rounded,
                    colors: AppColors.role(UserRole.buyer)),
              ]),
              const SizedBox(height: 12),
              FadeSlideIn(
                index: 3,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => StoreFormScreen(store: store))),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Дэлгүүрийн мэдээлэл засах'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================= Бараа нэмэх, засах, устгах =======================

class MerchantProductsTab extends StatelessWidget {
  const MerchantProductsTab({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = app.productsOfStore(store.id, onlyVisible: false);
    return Scaffold(
      appBar: AppBar(title: const Text('Бараа')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductFormScreen(storeId: store.id))),
        icon: const Icon(Icons.add),
        label: const Text('Бараа нэмэх'),
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined, text: 'Бараа нэмээгүй байна')
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              children: [
                for (final (i, p) in items.indexed)
                  FadeSlideIn(
                   index: i,
                   child: Card(
                    child: ListTile(
                      leading: ProductThumb(p, size: 48),
                      title: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PriceText(p),
                          Text('Үлдэгдэл: ${p.stock}'
                              '${p.approved ? '' : ' · Хяналт хүлээж буй'}',
                              style: TextStyle(
                                  color: p.approved ? null : Colors.orange)),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          switch (v) {
                            case 'edit':
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ProductFormScreen(
                                      storeId: store.id, product: p)));
                            case 'price':
                              _pricingDialog(context, p);
                            case 'delete':
                              _confirmDelete(context, p);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Засах')),
                          PopupMenuItem(
                              value: 'price', child: Text('Үнэ, урамшуулал')),
                          PopupMenuItem(value: 'delete', child: Text('Устгах')),
                        ],
                      ),
                    ),
                  )),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Бараа устгах уу?'),
        content: Text(p.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Болих')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Устгах')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).deleteProduct(p);
      toast(context, 'Устгагдлаа');
    }
  }

  /// Use case: Үнэ болон урамшуулал удирдах
  Future<void> _pricingDialog(BuildContext context, Product p) async {
    final price = TextEditingController(text: '${p.price}');
    var discount = p.discountPercent.toDouble();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Үнэ, урамшуулал'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Үндсэн үнэ (төг)'),
              ),
              const SizedBox(height: 16),
              Text('Хямдрал: ${discount.round()}%'),
              Slider(
                value: discount,
                max: 90,
                divisions: 18,
                label: '${discount.round()}%',
                onChanged: (v) => setLocal(() => discount = v),
              ),
            ],
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
      ),
    );
    final value = int.tryParse(price.text.trim());
    if (ok == true && value != null && context.mounted) {
      AppScope.read(context)
          .setPricing(p, price: value, discount: discount.round());
      toast(context, 'Үнэ шинэчлэгдлээ');
    }
    price.dispose();
  }
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, required this.storeId, this.product});

  final String storeId;
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _cat = TextEditingController(text: widget.product?.category);
  late final _price =
      TextEditingController(text: widget.product?.price.toString());
  late final _discount = TextEditingController(
      text: (widget.product?.discountPercent ?? 0).toString());
  late final _stock =
      TextEditingController(text: widget.product?.stock.toString());
  late final _desc = TextEditingController(text: widget.product?.description);

  @override
  void dispose() {
    for (final c in [_name, _cat, _price, _discount, _stock, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    AppScope.read(context).saveProduct(
      existing: widget.product,
      storeId: widget.storeId,
      name: _name.text.trim(),
      category: _cat.text.trim(),
      price: int.parse(_price.text.trim()),
      discount: int.tryParse(_discount.text.trim()) ?? 0,
      stock: int.parse(_stock.text.trim()),
      description: _desc.text.trim(),
    );
    Navigator.pop(context);
    toast(
        context,
        widget.product == null
            ? 'Бараа нэмэгдлээ (админы хяналт хүлээж байна)'
            : 'Бараа шинэчлэгдлээ');
  }

  @override
  Widget build(BuildContext context) {
    String? req(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Заавал бөглөнө' : null;
    String? number(String? v) =>
        int.tryParse(v?.trim() ?? '') == null ? 'Тоо оруулна уу' : null;
    InputDecoration deco(String l) =>
        InputDecoration(labelText: l);
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.product == null ? 'Бараа нэмэх' : 'Бараа засах')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
                controller: _name, decoration: deco('Нэр'), validator: req),
            const SizedBox(height: 12),
            TextFormField(
                controller: _cat,
                decoration: deco('Ангилал (Электрон, Хувцас, Ном ...)'),
                validator: req),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: deco('Үнэ (төг)'),
                    validator: number),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                    controller: _discount,
                    keyboardType: TextInputType.number,
                    decoration: deco('Хямдрал (%)')),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: deco('Үлдэгдэл'),
                validator: number),
            const SizedBox(height: 12),
            TextFormField(
                controller: _desc, maxLines: 3, decoration: deco('Тайлбар')),
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Хадгалах')),
          ],
        ),
      ),
    );
  }
}

// ======================= Захиалга боловсруулах =======================

class MerchantOrdersTab extends StatelessWidget {
  const MerchantOrdersTab({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final orders = app.ordersOfStore(store.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Захиалга боловсруулах')),
      body: orders.isEmpty
          ? const EmptyState(icon: Icons.inbox_outlined, text: 'Захиалга алга')
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final (i, o) in orders.indexed)
                  FadeSlideIn(
                    index: i,
                    child: OrderCard(
                      order: o,
                      footer: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${app.userById(o.buyerId)?.name ?? ''}: ${o.lines.map((l) => '${l.productName} × ${l.quantity}').join(', ')}',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (o.status == OrderStatus.paid)
                                  FilledButton.icon(
                                    onPressed: () => app.setOrderStatus(
                                        o, OrderStatus.processing),
                                    icon: const Icon(Icons.inventory_rounded),
                                    label: const Text('Хүлээн авч бэлтгэх'),
                                  ),
                                if (o.status == OrderStatus.processing)
                                  FilledButton.icon(
                                    onPressed: () => app.setOrderStatus(
                                        o, OrderStatus.readyForDelivery),
                                    icon: const Icon(Icons.outbox_rounded),
                                    label: const Text('Хүргэлтэд шилжүүлэх'),
                                  ),
                                if (o.status == OrderStatus.paid ||
                                    o.status == OrderStatus.processing)
                                  TextButton(
                                    onPressed: () => app.setOrderStatus(
                                        o, OrderStatus.cancelled),
                                    child: const Text('Цуцлах'),
                                  ),
                                TextButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                              buyerId: o.buyerId,
                                              storeId: store.id,
                                              asBuyer: false))),
                                  icon: const Icon(
                                      Icons.chat_bubble_outline_rounded),
                                  label: const Text('Холбогдох'),
                                ),
                              ],
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

// ======================= Борлуулалтын тайлан, статистик =======================

class SalesReportTab extends StatelessWidget {
  const SalesReportTab({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final orders = app
        .ordersOfStore(store.id)
        .where((o) => o.status != OrderStatus.cancelled)
        .toList();
    final revenue = orders.fold(0, (s, o) => s + o.total);
    final delivered =
        orders.where((o) => o.status == OrderStatus.delivered).length;
    final products = app.productsOfStore(store.id, onlyVisible: false);
    final rated = products.where((p) => p.reviews.isNotEmpty).toList();
    final avg = rated.isEmpty
        ? 0.0
        : rated.map((p) => p.rating).reduce((a, b) => a + b) / rated.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Борлуулалтын тайлан')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          StatGrid(children: [
            StatTile(
                label: 'Нийт борлуулалт',
                value: revenue,
                format: money,
                icon: Icons.payments_rounded,
                colors: AppColors.role(UserRole.merchant)),
            StatTile(
                label: 'Захиалга',
                value: orders.length,
                icon: Icons.receipt_long_rounded,
                colors: AppColors.role(UserRole.buyer)),
            StatTile(
                label: 'Хүргэгдсэн',
                value: delivered,
                icon: Icons.local_shipping_rounded,
                colors: AppColors.role(UserRole.courier)),
            StatTile(
                label: 'Дундаж үнэлгээ',
                value: avg,
                format: (v) => v.toStringAsFixed(1),
                icon: Icons.star_rounded,
                colors: const [Color(0xFFFFB300), Color(0xFFFFD54F)]),
          ]),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: 4,
            child: SectionCard(
              title: 'Барааны борлуулалт (ширхэг)',
              icon: Icons.bar_chart_rounded,
              child: SimpleBarChart(
                  data: app.unitsByProduct(store.id), format: (v) => '$v ш'),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= Хэрэглэгчтэй холбогдох =======================

class CustomerChatsTab extends StatelessWidget {
  const CustomerChatsTab({super.key, required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final buyers = app.buyersChattingWith(store.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Хэрэглэгчтэй холбогдох')),
      body: buyers.isEmpty
          ? const EmptyState(
              icon: Icons.forum_outlined, text: 'Хэрэглэгчийн мессеж алга')
          : ListView(
              children: [
                for (final b in buyers)
                  ListTile(
                    leading: CircleAvatar(
                        child: Text(
                            (app.userById(b)?.name ?? '?').characters.first)),
                    title: Text(app.userById(b)?.name ?? b),
                    subtitle: Text(
                      app.chatOf(b, store.id).last.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatScreen(
                            buyerId: b, storeId: store.id, asBuyer: false))),
                  ),
              ],
            ),
    );
  }
}
