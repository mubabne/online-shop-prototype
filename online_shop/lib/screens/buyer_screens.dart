import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

/// Зочин болон Худалдан авагчийн үндсэн дэлгэц.
/// Худалдан авагч нь Зочны бүх боломжийг өвлөнө (диаграмын generalization).
class BuyerHome extends StatefulWidget {
  const BuyerHome({super.key});

  @override
  State<BuyerHome> createState() => _BuyerHomeState();
}

class _BuyerHomeState extends State<BuyerHome> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final guest = app.isGuest;

    final pages = guest
        ? const [CatalogTab(), StoresTab(), GuestProfileTab()]
        : [
            const CatalogTab(),
            const StoresTab(),
            CartTab(onOrdered: () => setState(() => _tab = 3)),
            const OrdersTab(),
            const ProfileTab(),
          ];
    final destinations = guest
        ? const [
            NavigationDestination(
                icon: Icon(Icons.search), label: 'Бараа'),
            NavigationDestination(
                icon: Icon(Icons.store_outlined), label: 'Дэлгүүр'),
            NavigationDestination(
                icon: Icon(Icons.person_add_alt), label: 'Бүртгүүлэх'),
          ]
        : [
            const NavigationDestination(
                icon: Icon(Icons.search), label: 'Бараа'),
            const NavigationDestination(
                icon: Icon(Icons.store_outlined), label: 'Дэлгүүр'),
            NavigationDestination(
                icon: Badge(
                  isLabelVisible: app.cartCount > 0,
                  label: Text('${app.cartCount}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                label: 'Сагс'),
            const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined), label: 'Захиалга'),
            const NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Профайл'),
          ];
    final index = _tab.clamp(0, pages.length - 1);
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: destinations,
      ),
    );
  }
}

/// Зочин захиалга өгөх гэвэл бүртгэл үүсгэхийг санал болгоно.
Future<void> askToRegister(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Бүртгэл шаардлагатай'),
      content: const Text(
          'Сагсанд хийх, захиалга өгөх, дэлгүүртэй холбогдохын тулд бүртгэл үүсгэнэ үү.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Болих')),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()));
          },
          child: const Text('Бүртгүүлэх'),
        ),
      ],
    ),
  );
}

// ======================= Бараа хайх, харах =======================

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> {
  String _query = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final results = app.searchProducts(query: _query, category: _category);
    return Scaffold(
      appBar: AppBar(
        title: Text(app.isGuest
            ? 'Онлайн дэлгүүр (Зочин)'
            : 'Сайн байна уу, ${app.currentUser!.name}'),
        actions: [if (app.isGuest) const LogoutButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: SearchBar(
              hintText: 'Бараа, дэлгүүр хайх',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _query = v),
              elevation: const WidgetStatePropertyAll(1),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('Бүгд'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final c in app.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off, text: 'Илэрц олдсонгүй')
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 270,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: results.length,
                    itemBuilder: (_, i) => ProductCard(results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard(this.product, {super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productId: product.id))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: ProductThumb(product, size: 72)),
              const SizedBox(height: 8),
              // Том фонттой үед ч картын хэмжээнээс хэтрэхгүйн тулд таслана.
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(app.storeById(product.storeId).name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              Row(children: [
                Stars(product.rating, size: 13),
                Text(' (${product.reviews.length})',
                    style: const TextStyle(fontSize: 11)),
              ]),
              PriceText(product),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.productById(productId);
    if (p == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const EmptyState(icon: Icons.error_outline, text: 'Бараа олдсонгүй'));
    }
    final store = app.storeById(p.storeId);
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: ProductThumb(p, size: 160)),
          const SizedBox(height: 16),
          Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          PriceText(p),
          const SizedBox(height: 6),
          Row(children: [
            Stars(p.rating),
            Text('  ${p.rating.toStringAsFixed(1)} · ${p.reviews.length} үнэлгээ'),
          ]),
          const SizedBox(height: 4),
          Text('Үлдэгдэл: ${p.stock} ш',
              style: TextStyle(color: p.stock > 0 ? Colors.green : Colors.red)),
          const Divider(height: 28),
          Text(p.description),
          const Divider(height: 28),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.store)),
            title: Text(store.name),
            subtitle: Text(store.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StoreDetailScreen(storeId: store.id))),
          ),
          const Divider(height: 28),
          Text('Үнэлгээ, сэтгэгдэл',
              style: Theme.of(context).textTheme.titleMedium),
          if (p.reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Одоогоор үнэлгээ алга'),
            ),
          for (final r in p.reviews)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Row(children: [
                Text(r.userName),
                const SizedBox(width: 8),
                Stars(r.stars.toDouble(), size: 14),
              ]),
              subtitle: Text(r.comment),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => app.isGuest
                    ? askToRegister(context)
                    : Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatScreen(
                            buyerId: app.currentUser!.id,
                            storeId: store.id,
                            asBuyer: true))),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Холбогдох'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: p.stock == 0
                      ? null
                      : () {
                          if (app.isGuest) {
                            askToRegister(context);
                            return;
                          }
                          app.addToCart(p);
                          toast(context, 'Сагсанд нэмэгдлээ');
                        },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Сагсанд хийх'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= Дэлгүүр хайх =======================

class StoresTab extends StatefulWidget {
  const StoresTab({super.key});

  @override
  State<StoresTab> createState() => _StoresTabState();
}

class _StoresTabState extends State<StoresTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final stores = app.searchStores(_query);
    return Scaffold(
      appBar: AppBar(title: const Text('Дэлгүүр хайх')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: SearchBar(
              hintText: 'Дэлгүүрийн нэр, ангилал',
              leading: const Icon(Icons.store),
              onChanged: (v) => setState(() => _query = v),
              elevation: const WidgetStatePropertyAll(1),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final s in stores)
                  Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.store)),
                      title: Row(children: [
                        Flexible(child: Text(s.name)),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                      ]),
                      subtitle: Text(
                          '${s.category} · ${app.productsOfStore(s.id).length} бараа'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => StoreDetailScreen(storeId: s.id))),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StoreDetailScreen extends StatelessWidget {
  const StoreDetailScreen({super.key, required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final store = app.storeById(storeId);
    final items = app.productsOfStore(storeId);
    return Scaffold(
      appBar: AppBar(title: Text(store.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => app.isGuest
            ? askToRegister(context)
            : Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatScreen(
                    buyerId: app.currentUser!.id,
                    storeId: storeId,
                    asBuyer: true))),
        icon: const Icon(Icons.chat),
        label: const Text('Дэлгүүртэй холбогдох'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(store.description),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisExtent: 270,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => ProductCard(items[i]),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ======================= Сагс удирдах, Захиалга өгөх =======================

class CartTab extends StatelessWidget {
  const CartTab({super.key, required this.onOrdered});

  final VoidCallback onOrdered;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Сагс')),
      body: app.cart.isEmpty
          ? const EmptyState(
              icon: Icons.remove_shopping_cart_outlined,
              text: 'Сагс хоосон байна')
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final item in app.cart)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          ProductThumb(item.product),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                Text(app.storeById(item.product.storeId).name,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                                Text(money(item.total)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () =>
                                app.setCartQuantity(item, item.quantity - 1),
                          ),
                          Text('${item.quantity}'),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: item.quantity >= item.product.stock
                                ? null
                                : () => app.setCartQuantity(
                                    item, item.quantity + 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: app.cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Нийт: ${money(app.cartTotal)}',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final ok = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                                builder: (_) => const CheckoutScreen()));
                        if (ok == true) onOrdered();
                      },
                      child: const Text('Захиалга өгөх'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final TextEditingController _address;
  PaymentMethod _method = PaymentMethod.qpay;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(
        text: AppScope.read(context).currentUser?.address ?? '');
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final app = AppScope.read(context);
    if (_address.text.trim().isEmpty) {
      toast(context, 'Хүргэлтийн хаягаа оруулна уу');
      return;
    }
    final paid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PaymentGatewayDialog(amount: app.cartTotal, method: _method),
    );
    if (paid != true || !mounted) return;
    final orders = app.placeOrder(address: _address.text.trim(), method: _method);
    Navigator.of(context).pop(true);
    toast(context, '${orders.length} захиалга амжилттай үүслээ');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Захиалга баталгаажуулах')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Бараа', style: Theme.of(context).textTheme.titleMedium),
          for (final i in app.cart)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${i.product.name} × ${i.quantity}'),
              trailing: Text(money(i.total)),
            ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Нийт дүн',
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(money(app.cartTotal),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(
                labelText: 'Хүргэлтийн хаяг', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          Text('Төлбөрийн хэлбэр',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m in PaymentMethod.values)
                ChoiceChip(
                  label: Text(m.label),
                  selected: _method == m,
                  onSelected: (_) => setState(() => _method = m),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Дэлгүүр тус бүрийн бараа тусдаа захиалга болж үүснэ.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            onPressed: _pay,
            icon: const Icon(Icons.lock_outline),
            label: Text('${money(app.cartTotal)} төлөх'),
          ),
        ),
      ),
    );
  }
}

/// Use case: Төлбөр төлөх — гадаад "Төлбөрийн систем" актортай харилцахыг дуурайлгана.
class PaymentGatewayDialog extends StatefulWidget {
  const PaymentGatewayDialog(
      {super.key, required this.amount, required this.method});

  final int amount;
  final PaymentMethod method;

  @override
  State<PaymentGatewayDialog> createState() => _PaymentGatewayDialogState();
}

class _PaymentGatewayDialogState extends State<PaymentGatewayDialog> {
  bool _processing = false;
  bool _done = false;

  Future<void> _confirm() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _processing = false;
      _done = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.account_balance),
        const SizedBox(width: 8),
        Text('Төлбөрийн систем · ${widget.method.label}'),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(money(widget.amount),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (_processing) const CircularProgressIndicator(),
          if (_processing) const Text('\nГүйлгээ шалгаж байна...'),
          if (_done)
            const Column(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              Text('Төлбөр амжилттай'),
            ]),
          if (!_processing && !_done)
            const Text('Төлбөрийг баталгаажуулах уу? (прототип — бодит гүйлгээ хийгдэхгүй)'),
        ],
      ),
      actions: _processing || _done
          ? null
          : [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Цуцлах')),
              FilledButton(onPressed: _confirm, child: const Text('Төлөх')),
            ],
    );
  }
}

// ======================= Захиалга хянах =======================

class OrdersTab extends StatelessWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final orders = app.ordersOfBuyer(app.currentUser!.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Миний захиалга')),
      body: orders.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined, text: 'Захиалга алга')
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final o in orders)
                  Card(
                    child: ListTile(
                      title: Text('${o.id} · ${app.storeById(o.storeId).name}'),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${shortDate(o.createdAt)} · ${money(o.total)}'),
                            const SizedBox(height: 4),
                            StatusChip(o.status),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: o.id))),
                    ),
                  ),
              ],
            ),
    );
  }
}

const deliveryFlow = [
  OrderStatus.paid,
  OrderStatus.processing,
  OrderStatus.readyForDelivery,
  OrderStatus.courierAccepted,
  OrderStatus.scheduled,
  OrderStatus.onTheWay,
  OrderStatus.delivered,
];

class OrderTimeline extends StatelessWidget {
  const OrderTimeline(this.order, {super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.cancelled) {
      return const StatusChip(OrderStatus.cancelled);
    }
    final current = deliveryFlow.indexOf(order.status);
    return Column(
      children: [
        for (var i = 0; i < deliveryFlow.length; i++)
          Row(
            children: [
              Icon(
                i <= current ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: i <= current ? statusColor(deliveryFlow[i]) : Colors.grey,
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  deliveryFlow[i].label,
                  style: TextStyle(
                    fontWeight:
                        i == current ? FontWeight.bold : FontWeight.normal,
                    color: i <= current ? null : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final o = app.orders.firstWhere((o) => o.id == orderId);
    final complaint = app.complaintOf(o.id);
    final courier = app.userById(o.courierId);
    return Scaffold(
      appBar: AppBar(title: Text('Захиалга ${o.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(app.storeById(o.storeId).name,
              style: Theme.of(context).textTheme.titleLarge),
          Text('${shortDate(o.createdAt)} · ${o.paymentMethod.label}'),
          const SizedBox(height: 12),
          for (final l in o.lines)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${l.productName} × ${l.quantity}'),
              trailing: Text(money(l.total)),
            ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Нийт', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(money(o.total),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 24),
          Text('Хүргэлтийн явц', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          OrderTimeline(o),
          const SizedBox(height: 8),
          Text('Хаяг: ${o.address}'),
          if (courier != null) Text('Хүргэгч: ${courier.name} (${courier.phone})'),
          if (o.deliverySlot != null) Text('Хуваарь: ${o.deliverySlot}'),
          if (o.receivedBy != null) Text('Хүлээн авсан: ${o.receivedBy}'),
          const Divider(height: 24),
          if (complaint != null)
            Card(
              color: complaint.status == ComplaintStatus.open
                  ? Colors.orange.shade50
                  : Colors.green.shade50,
              child: ListTile(
                leading: Icon(complaint.status == ComplaintStatus.open
                    ? Icons.report_outlined
                    : Icons.task_alt),
                title: Text(complaint.status == ComplaintStatus.open
                    ? 'Гомдол шийдвэрлэгдэж байна'
                    : 'Гомдол шийдвэрлэгдсэн'),
                subtitle: Text(complaint.resolution == null
                    ? complaint.text
                    : '${complaint.text}\n\nХариу: ${complaint.resolution}'),
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (o.status == OrderStatus.delivered && !o.rated)
                FilledButton.icon(
                  onPressed: () => _rate(context, o),
                  icon: const Icon(Icons.star_outline),
                  label: const Text('Үнэлгээ өгөх'),
                ),
              if (complaint == null)
                OutlinedButton.icon(
                  onPressed: () => _complain(context, o),
                  icon: const Icon(Icons.report_outlined),
                  label: const Text('Гомдол мэдүүлэх'),
                ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ChatScreen(
                        buyerId: o.buyerId, storeId: o.storeId, asBuyer: true))),
                icon: const Icon(Icons.chat_outlined),
                label: const Text('Дэлгүүртэй холбогдох'),
              ),
              if (o.status == OrderStatus.paid)
                TextButton.icon(
                  onPressed: () => app.setOrderStatus(o, OrderStatus.cancelled),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Цуцлах'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _rate(BuildContext context, Order o) async {
    var stars = 5;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Үнэлгээ өгөх'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => IconButton(
                    icon: Icon(i < stars ? Icons.star : Icons.star_border,
                        color: Colors.amber),
                    onPressed: () => setLocal(() => stars = i + 1),
                  ),
                ),
              ),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                    hintText: 'Сэтгэгдэл', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Болих')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Илгээх')),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      AppScope.read(context).rateOrder(o, stars, ctrl.text.trim());
      toast(context, 'Үнэлгээ өгсөнд баярлалаа');
    }
    ctrl.dispose();
  }

  Future<void> _complain(BuildContext context, Order o) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Гомдол мэдүүлэх'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
              hintText: 'Захиалгад гарсан асуудлыг бичнэ үү',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Болих')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Илгээх')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty && context.mounted) {
      AppScope.read(context).fileComplaint(o, ctrl.text.trim());
      toast(context, 'Гомдол админд илгээгдлээ');
    }
    ctrl.dispose();
  }
}

// ======================= Бүртгэлээ удирдах =======================

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late final AppUser _user = AppScope.read(context).currentUser!;
  late final _name = TextEditingController(text: _user.name);
  late final _phone = TextEditingController(text: _user.phone);
  late final _email = TextEditingController(text: _user.email);
  late final _address = TextEditingController(text: _user.address);

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget field(TextEditingController c, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: c,
            decoration: InputDecoration(
                labelText: label, border: const OutlineInputBorder()),
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Бүртгэлээ удирдах'),
        actions: const [LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 36,
              child: Text(_user.name.characters.first,
                  style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 16),
          field(_name, 'Нэр'),
          field(_phone, 'Утас'),
          field(_email, 'И-мэйл'),
          field(_address, 'Хүргэлтийн хаяг'),
          FilledButton(
            onPressed: () {
              AppScope.read(context).updateProfile(
                name: _name.text.trim(),
                phone: _phone.text.trim(),
                email: _email.text.trim(),
                address: _address.text.trim(),
              );
              toast(context, 'Мэдээлэл хадгалагдлаа');
            },
            child: const Text('Хадгалах'),
          ),
        ],
      ),
    );
  }
}

class GuestProfileTab extends StatelessWidget {
  const GuestProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Зочин'), actions: const [LogoutButton()]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_add_alt_1, size: 64),
              const SizedBox(height: 12),
              const Text(
                'Захиалга өгөх, сагс ашиглах, үнэлгээ өгөхийн тулд бүртгэл үүсгэнэ үү.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const RegisterScreen())),
                child: const Text('Бүртгэл үүсгэх'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
