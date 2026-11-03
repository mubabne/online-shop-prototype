import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/animations.dart';
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
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Нүүр'),
            NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront_rounded),
                label: 'Дэлгүүр'),
            NavigationDestination(
                icon: Icon(Icons.person_add_alt_outlined),
                selectedIcon: Icon(Icons.person_add_alt_1_rounded),
                label: 'Бүртгүүлэх'),
          ]
        : [
            const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Нүүр'),
            const NavigationDestination(
                icon: Icon(Icons.storefront_outlined),
                selectedIcon: Icon(Icons.storefront_rounded),
                label: 'Дэлгүүр'),
            NavigationDestination(
                icon: BumpOnChange(
                  value: app.cartCount,
                  child: Badge(
                    isLabelVisible: app.cartCount > 0,
                    label: Text('${app.cartCount}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
                selectedIcon: const Icon(Icons.shopping_bag_rounded),
                label: 'Сагс'),
            const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Захиалга'),
            const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Профайл'),
          ];
    final index = _tab.clamp(0, pages.length - 1);
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
      ),
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
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_open_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Бүртгэл шаардлагатай',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text(
              'Сагсанд хийх, захиалга өгөх, дэлгүүртэй холбогдохын тулд бүртгэл үүсгэнэ үү.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const RegisterScreen()));
                },
                child: const Text('Бүртгүүлэх'),
              ),
            ),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Дараа')),
          ],
        ),
      ),
    ),
  );
}

void addToCartWithFeedback(BuildContext context, Product p, [int qty = 1]) {
  final app = AppScope.read(context);
  if (app.isGuest) {
    askToRegister(context);
    return;
  }
  app.addToCart(p, qty);
  toast(context, '${p.name} сагсанд нэмэгдлээ',
      icon: Icons.shopping_bag_rounded);
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
    final deals = app.searchProducts().where((p) => p.discountPercent > 0).toList();
    final showPromo = _query.isEmpty && _category == null;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: GradientHeader(
            subtitle: 'Сайн байна уу,',
            title: app.isGuest ? 'Зочин' : app.currentUser!.name,
            colors: AppColors.brandGradient.colors,
            icon: Icons.waving_hand_rounded,
            trailing: app.isGuest
                ? const LogoutButton(color: Colors.white)
                : null,
            bottom: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Бараа, дэлгүүр хайх',
                prefixIcon: const Icon(Icons.search_rounded),
                fillColor: Theme.of(context).cardTheme.color,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        if (showPromo && deals.isNotEmpty)
          SliverToBoxAdapter(child: PromoCarousel(products: deals)),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              children: [
                _CategoryChip(
                  label: 'Бүгд',
                  icon: Icons.apps_rounded,
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in app.categories)
                  _CategoryChip(
                    label: c,
                    icon: AppColors.category(c).$1,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(_query.isEmpty ? 'Бүх бараа' : 'Хайлтын илэрц',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${results.length} бараа',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
        if (results.isEmpty)
          const SliverToBoxAdapter(
            child: EmptyState(icon: Icons.search_off, text: 'Илэрц олдсонгүй'),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 280,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: results.length,
              itemBuilder: (_, i) => FadeSlideIn(
                key: ValueKey('${results[i].id}-$_category-$_query'),
                index: i,
                child: ProductCard(results[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.brandGradient : null,
            color: selected ? null : Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: selected
                    ? Colors.transparent
                    : scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 18, color: selected ? Colors.white : scheme.primary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : scheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Хямдралтай барааг автоматаар гүйлгэх баннер.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key, required this.products});

  final List<Product> products;

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final _ctrl = PageController(viewportFraction: 0.9);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_ctrl.hasClients || widget.products.length < 2) return;
      final next = (_page + 1) % widget.products.length;
      _ctrl.animateToPage(next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: widget.products.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final p = widget.products[i];
              final colors = AppColors.category(p.category).$2;
              return AnimatedScale(
                scale: i == _page ? 1 : 0.94,
                duration: const Duration(milliseconds: 300),
                child: Pressable(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(productId: p.id))),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -30,
                          child: Icon(AppColors.category(p.category).$1,
                              size: 150,
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                    '🔥 ${p.discountPercent}% ХЯМДРАЛ',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800)),
                              ),
                              const Spacer(),
                              Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800)),
                              Text(
                                  '${app.storeById(p.storeId).name} · ${money(p.finalPrice)}',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.products.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _page
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard(this.product, {super.key, this.heroPrefix = 'grid'});

  final Product product;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final heroTag = '$heroPrefix-${product.id}';
    return Pressable(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              ProductDetailScreen(productId: product.id, heroTag: heroTag))),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  LayoutBuilder(
                    builder: (_, c) => ProductThumb(product,
                        size: c.maxWidth,
                        height: 130,
                        radius: 16,
                        heroTag: heroTag),
                  ),
                  if (product.discountPercent > 0)
                    Positioned(
                        top: 8,
                        left: 8,
                        child: DiscountBadge(product.discountPercent)),
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: product.stock == 0
                            ? null
                            : () => addToCartWithFeedback(context, product),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(Icons.add_shopping_cart_rounded,
                              size: 18, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.storefront_rounded,
                            size: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(app.storeById(product.storeId).name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
              Row(children: [
                const Icon(Icons.star_rounded,
                    size: 15, color: Color(0xFFFFB300)),
                Text(
                    ' ${product.rating.toStringAsFixed(1)} (${product.reviews.length})',
                    style: const TextStyle(fontSize: 12)),
              ]),
              PriceText(product),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId, this.heroTag});

  final String productId;
  final Object? heroTag;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _added = false;

  void _add(Product p) {
    final app = AppScope.read(context);
    if (app.isGuest) {
      askToRegister(context);
      return;
    }
    app.addToCart(p, _qty);
    setState(() => _added = true);
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final p = app.productById(widget.productId);
    if (p == null) {
      return Scaffold(
          appBar: AppBar(),
          body: const EmptyState(
              icon: Icons.error_outline, text: 'Бараа олдсонгүй'));
    }
    final store = app.storeById(p.storeId);
    final colors = AppColors.category(p.category).$2;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            stretch: true,
            backgroundColor: colors.first,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: ProductThumb(p,
                        size: 190,
                        radius: 48,
                        heroTag: widget.heroTag ?? 'detail-${p.id}'),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeSlideIn(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(p.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        if (p.discountPercent > 0)
                          DiscountBadge(p.discountPercent),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeSlideIn(index: 1, child: PriceText(p, large: true)),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 2,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                          icon: Icons.star_rounded,
                          color: const Color(0xFFFFB300),
                          text:
                              '${p.rating.toStringAsFixed(1)} · ${p.reviews.length} үнэлгээ',
                        ),
                        _InfoPill(
                          icon: p.stock > 0
                              ? Icons.inventory_2_rounded
                              : Icons.block_rounded,
                          color: p.stock > 0 ? Colors.green : Colors.red,
                          text: p.stock > 0 ? 'Үлдэгдэл ${p.stock}' : 'Дууссан',
                        ),
                        _InfoPill(
                          icon: AppColors.category(p.category).$1,
                          color: colors.first,
                          text: p.category,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    index: 3,
                    child: Text(p.description,
                        style: const TextStyle(fontSize: 15, height: 1.5)),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    index: 4,
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(Icons.storefront_rounded,
                              color: scheme.primary),
                        ),
                        title: Row(children: [
                          Flexible(
                            child: Text(store.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 16, color: Color(0xFF4F7CFF)),
                        ]),
                        subtitle: Text(store.description),
                        trailing: IconButton.filledTonal(
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                          onPressed: () => app.isGuest
                              ? askToRegister(context)
                              : Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                      buyerId: app.currentUser!.id,
                                      storeId: store.id,
                                      asBuyer: true))),
                        ),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    StoreDetailScreen(storeId: store.id))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Үнэлгээ, сэтгэгдэл',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  if (p.reviews.isEmpty)
                    Text('Одоогоор үнэлгээ алга',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  for (var i = 0; i < p.reviews.length; i++)
                    FadeSlideIn(
                      index: 5 + i,
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                              child: Text(
                                  p.reviews[i].userName.characters.first)),
                          title: Row(children: [
                            Text(p.reviews[i].userName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            Stars(p.reviews[i].stars.toDouble(), size: 14),
                          ]),
                          subtitle: p.reviews[i].comment.isEmpty
                              ? null
                              : Text(p.reviews[i].comment),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                QuantityStepper(
                  value: _qty,
                  max: p.stock,
                  onChanged: (v) => setState(() => _qty = v),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _added ? Colors.green : null,
                      ),
                      onPressed: p.stock == 0 || _added ? null : () => _add(p),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: _added
                            ? const Row(
                                key: ValueKey('added'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_rounded),
                                  SizedBox(width: 6),
                                  Text('Нэмэгдлээ'),
                                ],
                              )
                            : Text(
                                key: const ValueKey('add'),
                                'Сагсанд хийх · ${money(p.finalPrice * _qty)}'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(
      {required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.compact = false,
  });

  final int value;
  final int min;
  final int max;
  final bool compact;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = compact ? 30.0 : 40.0;
    Widget btn(IconData icon, VoidCallback? onTap) => SizedBox(
          width: size,
          height: size,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: compact ? 16 : 20,
            onPressed: onTap,
            icon: Icon(icon),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove_rounded,
              value > min ? () => onChanged(value - 1) : null),
          SizedBox(
            width: compact ? 22 : 28,
            child: BumpOnChange(
              value: value,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
          btn(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null),
        ],
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
      appBar: AppBar(title: const Text('Дэлгүүрүүд')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Дэлгүүрийн нэр, ангилал',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 12),
          if (stores.isEmpty)
            const EmptyState(
                icon: Icons.store_mall_directory_outlined,
                text: 'Дэлгүүр олдсонгүй'),
          for (var i = 0; i < stores.length; i++)
            FadeSlideIn(
              key: ValueKey('${stores[i].id}-$_query'),
              index: i,
              child: _StoreCard(store: stores[i]),
            ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final (icon, colors) = AppColors.category(store.category);
    final products = app.productsOfStore(store.id);
    return Pressable(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StoreDetailScreen(storeId: store.id))),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors),
              ),
              child: Stack(children: [
                Positioned(
                  right: 10,
                  top: -10,
                  child: Icon(icon,
                      size: 90, color: Colors.white.withValues(alpha: 0.2)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(store.name,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 18, color: Color(0xFF4F7CFF)),
                        ]),
                        const SizedBox(height: 2),
                        Text(store.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.first.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${products.length} бараа',
                        style: TextStyle(
                            color: colors.first, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final (icon, colors) = AppColors.category(store.category);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => app.isGuest
            ? askToRegister(context)
            : Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatScreen(
                    buyerId: app.currentUser!.id,
                    storeId: storeId,
                    asBuyer: true))),
        icon: const Icon(Icons.chat_rounded),
        label: const Text('Холбогдох'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: colors.first,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(store.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
                child: Stack(children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(icon,
                        size: 180, color: Colors.white.withValues(alpha: 0.18)),
                  ),
                ]),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Text(store.description,
                  style: const TextStyle(fontSize: 15)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 280,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => FadeSlideIn(
                index: i,
                child: ProductCard(items[i], heroPrefix: 'store'),
              ),
            ),
          ),
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
      appBar: AppBar(title: const Text('Миний сагс')),
      body: app.cart.isEmpty
          ? const EmptyState(
              icon: Icons.shopping_bag_outlined,
              text: 'Сагс хоосон байна.\nДуртай бараагаа нэмээрэй!')
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('← Устгахын тулд зүүн тийш шудрана уу',
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
                for (var i = 0; i < app.cart.length; i++)
                  FadeSlideIn(
                    key: ValueKey(app.cart[i].product.id),
                    index: i,
                    child: Dismissible(
                      key: ValueKey('d-${app.cart[i].product.id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        final item = app.cart[i];
                        app.setCartQuantity(item, 0);
                        toast(context, '${item.product.name} хасагдлаа',
                            icon: Icons.delete_outline);
                      },
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E57),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.delete_rounded,
                            color: Colors.white),
                      ),
                      child: _CartItemCard(item: app.cart[i]),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: app.cart.isEmpty
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Нийт (${app.cartCount} ш)',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                            CountUpText(
                              value: app.cartTotal,
                              format: money,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          final ok = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                  builder: (_) => const CheckoutScreen()));
                          if (ok == true) onOrdered();
                        },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Захиалах'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ProductThumb(item.product, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(app.storeById(item.product.storeId).name,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(money(item.total),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
            ),
            QuantityStepper(
              compact: true,
              value: item.quantity,
              min: 0,
              max: item.product.stock,
              onChanged: (v) => app.setCartQuantity(item, v),
            ),
          ],
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
      toast(context, 'Хүргэлтийн хаягаа оруулна уу', icon: Icons.info_outline);
      return;
    }
    final paid = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          PaymentGatewayDialog(amount: app.cartTotal, method: _method),
    );
    if (paid != true || !mounted) return;
    final orders =
        app.placeOrder(address: _address.text.trim(), method: _method);
    Navigator.of(context).pop(true);
    toast(context, '${orders.length} захиалга амжилттай үүслээ');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    const methodIcons = {
      PaymentMethod.card: Icons.credit_card_rounded,
      PaymentMethod.qpay: Icons.qr_code_2_rounded,
      PaymentMethod.socialPay: Icons.account_balance_wallet_rounded,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Төлбөр төлөх')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FadeSlideIn(
            child: SectionCard(
              title: 'Захиалгын бараа',
              icon: Icons.shopping_bag_outlined,
              child: Column(
                children: [
                  for (final i in app.cart)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        ProductThumb(i.product, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text('${i.product.name} × ${i.quantity}')),
                        Text(money(i.total),
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  const Divider(height: 20),
                  Row(children: [
                    const Expanded(
                        child: Text('Нийт дүн',
                            style: TextStyle(fontWeight: FontWeight.w800))),
                    Text(money(app.cartTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: AppColors.primary)),
                  ]),
                ],
              ),
            ),
          ),
          FadeSlideIn(
            index: 1,
            child: SectionCard(
              title: 'Хүргэлтийн хаяг',
              icon: Icons.location_on_outlined,
              child: TextField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(hintText: 'Хаяг'),
              ),
            ),
          ),
          FadeSlideIn(
            index: 2,
            child: SectionCard(
              title: 'Төлбөрийн хэлбэр',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  for (final m in PaymentMethod.values)
                    Pressable(
                      onTap: () => setState(() => _method = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _method == m
                              ? scheme.primaryContainer.withValues(alpha: 0.6)
                              : null,
                          border: Border.all(
                            width: 2,
                            color: _method == m
                                ? scheme.primary
                                : scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(children: [
                          Icon(methodIcons[m], color: scheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(m.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _method == m
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              key: ValueKey(_method == m),
                              color: scheme.primary,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  Text(
                    'Дэлгүүр тус бүрийн бараа тусдаа захиалга болж үүснэ.',
                    style:
                        TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _pay,
            icon: const Icon(Icons.lock_rounded),
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
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_done) {
      body = Column(
        key: const ValueKey('done'),
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF2ECC71),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 48),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Төлбөр амжилттай!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      );
    } else if (_processing) {
      body = const Column(
        key: ValueKey('processing'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(strokeWidth: 5)),
          SizedBox(height: 16),
          Text('Гүйлгээ шалгаж байна...'),
        ],
      );
    } else {
      body = Column(
        key: const ValueKey('confirm'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(money(widget.amount),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text(
            'Төлбөрийг баталгаажуулах уу?\n(прототип — бодит гүйлгээ хийгдэхгүй)',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return AlertDialog(
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_rounded,
              color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Төлбөрийн систем · ${widget.method.label}',
              style: const TextStyle(fontSize: 17)),
        ),
      ]),
      content: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: body,
        ),
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

const deliveryFlow = [
  OrderStatus.paid,
  OrderStatus.processing,
  OrderStatus.readyForDelivery,
  OrderStatus.courierAccepted,
  OrderStatus.scheduled,
  OrderStatus.onTheWay,
  OrderStatus.delivered,
];

double orderProgress(Order o) => o.status == OrderStatus.cancelled
    ? 0
    : (deliveryFlow.indexOf(o.status) + 1) / deliveryFlow.length;

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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: [
                for (var i = 0; i < orders.length; i++)
                  FadeSlideIn(
                    index: i,
                    child: OrderCard(
                      order: orders[i],
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailScreen(orderId: orders[i].id))),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Захиалгын товч карт, явцын мөртэй.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onTap, this.footer});

  final Order order;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final color = statusColor(order.status);
    return Pressable(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(statusIcon(order.status), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.storeById(order.storeId).name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      Text('${order.id} · ${shortDate(order.createdAt)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                ),
                Text(money(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                StatusChip(order.status),
                const SizedBox(width: 10),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: orderProgress(order)),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
              ]),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

class OrderTimeline extends StatelessWidget {
  const OrderTimeline(this.order, {super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.cancelled) {
      return const StatusChip(OrderStatus.cancelled);
    }
    final current = deliveryFlow.indexOf(order.status);
    final muted = Theme.of(context).colorScheme.outlineVariant;
    return Column(
      children: [
        for (var i = 0; i < deliveryFlow.length; i++)
          FadeSlideIn(
            index: i,
            offset: const Offset(0.1, 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: i == current ? 30 : 24,
                        height: i == current ? 30 : 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= current
                              ? statusColor(deliveryFlow[i])
                              : Colors.transparent,
                          border: Border.all(
                              color: i <= current
                                  ? statusColor(deliveryFlow[i])
                                  : muted,
                              width: 2),
                          boxShadow: i == current
                              ? [
                                  BoxShadow(
                                    color: statusColor(deliveryFlow[i])
                                        .withValues(alpha: 0.4),
                                    blurRadius: 10,
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          i <= current
                              ? statusIcon(deliveryFlow[i])
                              : Icons.circle,
                          size: i <= current ? 15 : 6,
                          color: i <= current ? Colors.white : muted,
                        ),
                      ),
                      if (i < deliveryFlow.length - 1)
                        Expanded(
                          child: Container(
                            width: 3,
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            decoration: BoxDecoration(
                              color: i < current
                                  ? statusColor(deliveryFlow[i + 1])
                                  : muted,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3, bottom: 16),
                      child: Text(
                        deliveryFlow[i].label,
                        style: TextStyle(
                          fontWeight: i == current
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: i <= current ? null : muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
    final color = statusColor(o.status);
    return Scaffold(
      appBar: AppBar(title: Text('Захиалга ${o.id}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(children: [
                Icon(statusIcon(o.status), color: Colors.white, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.status.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800)),
                      Text(
                          '${app.storeById(o.storeId).name} · ${o.paymentMethod.label}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            index: 1,
            child: SectionCard(
              title: 'Бараа',
              icon: Icons.shopping_bag_outlined,
              child: Column(children: [
                for (final l in o.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Expanded(child: Text('${l.productName} × ${l.quantity}')),
                      Text(money(l.total)),
                    ]),
                  ),
                const Divider(height: 18),
                Row(children: [
                  const Expanded(
                      child: Text('Нийт',
                          style: TextStyle(fontWeight: FontWeight.w800))),
                  Text(money(o.total),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ]),
              ]),
            ),
          ),
          FadeSlideIn(
            index: 2,
            child: SectionCard(
              title: 'Хүргэлтийн явц',
              icon: Icons.route_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrderTimeline(o),
                  _detail(Icons.location_on_outlined, o.address),
                  if (courier != null)
                    _detail(Icons.delivery_dining_outlined,
                        '${courier.name} (${courier.phone})'),
                  if (o.deliverySlot != null)
                    _detail(Icons.schedule_rounded, o.deliverySlot!),
                  if (o.receivedBy != null)
                    _detail(Icons.how_to_reg_outlined,
                        'Хүлээн авсан: ${o.receivedBy}'),
                ],
              ),
            ),
          ),
          if (complaint != null)
            FadeSlideIn(
              index: 3,
              child: Card(
                color: (complaint.status == ComplaintStatus.open
                        ? Colors.orange
                        : Colors.green)
                    .withValues(alpha: 0.12),
                child: ListTile(
                  leading: Icon(
                      complaint.status == ComplaintStatus.open
                          ? Icons.report_outlined
                          : Icons.task_alt,
                      color: complaint.status == ComplaintStatus.open
                          ? Colors.orange
                          : Colors.green),
                  title: Text(complaint.status == ComplaintStatus.open
                      ? 'Гомдол шийдвэрлэгдэж байна'
                      : 'Гомдол шийдвэрлэгдсэн'),
                  subtitle: Text(complaint.resolution == null
                      ? complaint.text
                      : '${complaint.text}\n\nХариу: ${complaint.resolution}'),
                ),
              ),
            ),
          const SizedBox(height: 12),
          FadeSlideIn(
            index: 4,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (o.status == OrderStatus.delivered && !o.rated)
                  FilledButton.icon(
                    onPressed: () => _rate(context, o),
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Үнэлгээ өгөх'),
                  ),
                if (complaint == null)
                  OutlinedButton.icon(
                    onPressed: () => _complain(context, o),
                    icon: const Icon(Icons.report_outlined),
                    label: const Text('Гомдол мэдүүлэх'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => ChatScreen(
                              buyerId: o.buyerId,
                              storeId: o.storeId,
                              asBuyer: true))),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Дэлгүүртэй холбогдох'),
                ),
                if (o.status == OrderStatus.paid)
                  TextButton.icon(
                    onPressed: () =>
                        app.setOrderStatus(o, OrderStatus.cancelled),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Цуцлах'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );

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
                    icon: AnimatedScale(
                      scale: i < stars ? 1.15 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 34,
                          color: const Color(0xFFFFB300)),
                    ),
                    onPressed: () => setLocal(() => stars = i + 1),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(hintText: 'Сэтгэгдэл'),
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
      toast(context, 'Үнэлгээ өгсөнд баярлалаа', icon: Icons.star_rounded);
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
              hintText: 'Захиалгад гарсан асуудлыг бичнэ үү'),
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
      toast(context, 'Гомдол админд илгээгдлээ', icon: Icons.send_rounded);
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
    final app = AppScope.of(context);
    final orders = app.ordersOfBuyer(_user.id);
    final spent = orders
        .where((o) => o.status != OrderStatus.cancelled)
        .fold(0, (s, o) => s + o.total);
    final fields = [
      (_name, 'Нэр', Icons.person_outline),
      (_phone, 'Утас', Icons.phone_outlined),
      (_email, 'И-мэйл', Icons.alternate_email),
      (_address, 'Хүргэлтийн хаяг', Icons.location_on_outlined),
    ];
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        GradientHeader(
          subtitle: 'Бүртгэлээ удирдах',
          title: _user.name,
          colors: AppColors.role(UserRole.buyer),
          icon: Icons.person_rounded,
          trailing: const LogoutButton(color: Colors.white),
          bottom: Row(children: [
            Expanded(
                child: _HeaderStat(
                    label: 'Захиалга', child: CountUpText(value: orders.length,
                        style: _HeaderStat.valueStyle))),
            Expanded(
                child: _HeaderStat(
                    label: 'Нийт зарцуулсан',
                    child: CountUpText(
                        value: spent,
                        format: money,
                        style: _HeaderStat.valueStyle))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (var i = 0; i < fields.length; i++)
                FadeSlideIn(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: TextField(
                      controller: fields[i].$1,
                      decoration: InputDecoration(
                          labelText: fields[i].$2,
                          prefixIcon: Icon(fields[i].$3)),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_rounded),
                  onPressed: () {
                    AppScope.read(context).updateProfile(
                      name: _name.text.trim(),
                      phone: _phone.text.trim(),
                      email: _email.text.trim(),
                      address: _address.text.trim(),
                    );
                    toast(context, 'Мэдээлэл хадгалагдлаа');
                  },
                  label: const Text('Хадгалах'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.child});

  final String label;
  final Widget child;

  static const valueStyle = TextStyle(
      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(fit: BoxFit.scaleDown, child: child),
          Text(label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

class GuestProfileTab extends StatelessWidget {
  const GuestProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final perks = [
      (Icons.shopping_bag_rounded, 'Сагс ашиглаж захиалга өгөх'),
      (Icons.local_shipping_rounded, 'Захиалгаа бодит цагт хянах'),
      (Icons.star_rounded, 'Үнэлгээ, сэтгэгдэл үлдээх'),
      (Icons.chat_rounded, 'Дэлгүүртэй шууд холбогдох'),
    ];
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        GradientHeader(
          subtitle: 'Та зочноор нэвтэрсэн байна',
          title: 'Бүртгүүлээрэй',
          colors: AppColors.brandGradient.colors,
          icon: Icons.person_add_alt_1_rounded,
          trailing: const LogoutButton(color: Colors.white),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              for (var i = 0; i < perks.length; i++)
                FadeSlideIn(
                  index: i,
                  child: Card(
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(perks[i].$1, color: Colors.white),
                      ),
                      title: Text(perks[i].$2,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Бүртгэл үүсгэх'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
