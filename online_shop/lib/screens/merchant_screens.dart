import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';

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
                  labelText: 'Дэлгүүрийн нэр', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _cat,
              decoration: const InputDecoration(
                  labelText: 'Ангилал', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Тайлбар', border: OutlineInputBorder())),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(store.name),
        actions: const [LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: store.verified ? Colors.green.shade50 : Colors.orange.shade50,
            child: ListTile(
              leading: Icon(
                  store.verified ? Icons.verified : Icons.hourglass_top,
                  color: store.verified ? Colors.green : Colors.orange),
              title: Text(store.verified
                  ? 'Баталгаажсан дэлгүүр'
                  : 'Админы баталгаажуулалт хүлээж байна'),
              subtitle: Text(store.verified
                  ? 'Таны бараа хэрэглэгчдэд харагдаж байна.'
                  : 'Баталгаажих хүртэл бараа хайлтад гарахгүй.'),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Ангилал'),
            subtitle: Text(store.category),
          ),
          ListTile(
            title: const Text('Тайлбар'),
            subtitle: Text(store.description),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            children: [
              StatTile(
                  label: 'Бараа',
                  value: '${app.productsOfStore(store.id, onlyVisible: false).length}',
                  icon: Icons.inventory_2_outlined),
              StatTile(
                  label: 'Идэвхтэй захиалга',
                  value: '$active',
                  icon: Icons.pending_actions),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StoreFormScreen(store: store))),
            icon: const Icon(Icons.edit),
            label: const Text('Дэлгүүрийн мэдээлэл засах'),
          ),
        ],
      ),
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
                for (final p in items)
                  Card(
                    child: ListTile(
                      leading: ProductThumb(p, size: 44),
                      title: Text(p.name),
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
                  ),
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
                    labelText: 'Үндсэн үнэ (төг)', border: OutlineInputBorder()),
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
        InputDecoration(labelText: l, border: const OutlineInputBorder());
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
                for (final o in orders)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(o.id,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ),
                            StatusChip(o.status),
                          ]),
                          const SizedBox(height: 4),
                          Text(
                              '${app.userById(o.buyerId)?.name ?? ''} · ${shortDate(o.createdAt)}'),
                          for (final l in o.lines)
                            Text('• ${l.productName} × ${l.quantity}'),
                          Text('Нийт: ${money(o.total)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (o.status == OrderStatus.paid)
                                FilledButton(
                                  onPressed: () => app.setOrderStatus(
                                      o, OrderStatus.processing),
                                  child: const Text('Хүлээн авч бэлтгэх'),
                                ),
                              if (o.status == OrderStatus.processing)
                                FilledButton(
                                  onPressed: () => app.setOrderStatus(
                                      o, OrderStatus.readyForDelivery),
                                  child: const Text('Хүргэлтэд шилжүүлэх'),
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
                                icon: const Icon(Icons.chat_outlined),
                                label: const Text('Холбогдох'),
                              ),
                            ],
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              StatTile(
                  label: 'Нийт борлуулалт',
                  value: money(revenue),
                  icon: Icons.payments_outlined),
              StatTile(
                  label: 'Захиалга',
                  value: '${orders.length}',
                  icon: Icons.receipt_long),
              StatTile(
                  label: 'Хүргэгдсэн',
                  value: '$delivered',
                  icon: Icons.local_shipping),
              StatTile(
                  label: 'Дундаж үнэлгээ',
                  value: avg.toStringAsFixed(1),
                  icon: Icons.star_outline),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Барааны борлуулалт (ширхэг)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SimpleBarChart(
                      data: app.unitsByProduct(store.id),
                      format: (v) => '$v ш'),
                ],
              ),
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
