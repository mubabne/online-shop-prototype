import 'package:flutter/widgets.dart';

import 'models.dart';

/// Прототипын бүх өгөгдлийг санах ойд хадгалах төлөв.
/// Бодит системд энэ хэсгийг API / өгөгдлийн сангаар солино.
class AppState extends ChangeNotifier {
  AppState() {
    _seed();
  }

  final List<AppUser> users = [];
  final List<Store> stores = [];
  final List<Product> products = [];
  final List<Order> orders = [];
  final List<Complaint> complaints = [];
  final Map<String, List<ChatMessage>> chats = {};
  final List<CartItem> cart = [];

  AppUser? currentUser;
  bool isGuest = false;
  int _seq = 100;

  String _nextId(String prefix) => '$prefix${_seq++}';

  // ---------------- Нэвтрэлт / бүртгэл ----------------

  List<AppUser> usersByRole(UserRole role) =>
      users.where((u) => u.role == role).toList();

  void loginAs(AppUser user) {
    currentUser = user;
    isGuest = false;
    notifyListeners();
  }

  void continueAsGuest() {
    currentUser = null;
    isGuest = true;
    notifyListeners();
  }

  /// Use case: Бүртгэл үүсгэх
  AppUser register({
    required String name,
    required String phone,
    String email = '',
    String address = '',
  }) {
    final user = AppUser(
      id: _nextId('u'),
      name: name,
      phone: phone,
      email: email,
      address: address,
      role: UserRole.buyer,
    );
    users.add(user);
    loginAs(user);
    return user;
  }

  /// Use case: Бүртгэлээ удирдах
  void updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
  }) {
    final u = currentUser!;
    u
      ..name = name
      ..phone = phone
      ..email = email
      ..address = address;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    isGuest = false;
    cart.clear();
    notifyListeners();
  }

  // ---------------- Хайлт ----------------

  Store storeById(String id) => stores.firstWhere((s) => s.id == id);
  Product? productById(String id) =>
      products.where((p) => p.id == id).firstOrNull;
  AppUser? userById(String? id) => users.where((u) => u.id == id).firstOrNull;

  List<String> get categories =>
      searchProducts().map((p) => p.category).toSet().toList()..sort();

  /// Use case: Бараа хайх, харах (зөвхөн баталгаажсан дэлгүүрийн зөвшөөрөгдсөн бараа)
  List<Product> searchProducts({String query = '', String? category}) {
    final q = query.trim().toLowerCase();
    return products.where((p) {
      final store = storeById(p.storeId);
      if (!p.approved || !store.verified) return false;
      if (category != null && p.category != category) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          store.name.toLowerCase().contains(q);
    }).toList();
  }

  /// Use case: Дэлгүүр хайх (Бараа хайх-ын extension point)
  List<Store> searchStores(String query) {
    final q = query.trim().toLowerCase();
    return stores
        .where((s) =>
            s.verified &&
            (q.isEmpty ||
                s.name.toLowerCase().contains(q) ||
                s.category.toLowerCase().contains(q)))
        .toList();
  }

  List<Product> productsOfStore(String storeId, {bool onlyVisible = true}) =>
      products
          .where((p) => p.storeId == storeId && (!onlyVisible || p.approved))
          .toList();

  // ---------------- Сагс удирдах ----------------

  int get cartCount => cart.fold(0, (s, i) => s + i.quantity);
  int get cartTotal => cart.fold(0, (s, i) => s + i.total);

  void addToCart(Product p, [int qty = 1]) {
    final existing = cart.where((c) => c.product.id == p.id).firstOrNull;
    if (existing != null) {
      existing.quantity += qty;
    } else {
      cart.add(CartItem(p, qty));
    }
    notifyListeners();
  }

  void setCartQuantity(CartItem item, int qty) {
    if (qty <= 0) {
      cart.remove(item);
    } else {
      item.quantity = qty;
    }
    notifyListeners();
  }

  // ---------------- Захиалга өгөх + Төлбөр төлөх ----------------

  /// Сагсыг дэлгүүр тус бүрээр нь тусдаа захиалга болгон үүсгэнэ.
  List<Order> placeOrder({
    required String address,
    required PaymentMethod method,
  }) {
    final byStore = <String, List<CartItem>>{};
    for (final item in cart) {
      byStore.putIfAbsent(item.product.storeId, () => []).add(item);
    }
    final created = <Order>[];
    byStore.forEach((storeId, items) {
      final order = Order(
        id: _nextId('ORD-'),
        buyerId: currentUser!.id,
        storeId: storeId,
        address: address,
        paymentMethod: method,
        createdAt: DateTime.now(),
        lines: items
            .map((i) => OrderLine(
                  productId: i.product.id,
                  productName: i.product.name,
                  unitPrice: i.product.finalPrice,
                  quantity: i.quantity,
                ))
            .toList(),
      );
      for (final i in items) {
        i.product.stock = (i.product.stock - i.quantity).clamp(0, 1 << 30);
      }
      orders.insert(0, order);
      created.add(order);
    });
    cart.clear();
    notifyListeners();
    return created;
  }

  List<Order> ordersOfBuyer(String buyerId) =>
      orders.where((o) => o.buyerId == buyerId).toList();

  List<Order> ordersOfStore(String storeId) =>
      orders.where((o) => o.storeId == storeId).toList();

  void setOrderStatus(Order o, OrderStatus status) {
    o.status = status;
    o.history.add(DateTime.now());
    notifyListeners();
  }

  /// Use case: Үнэлгээ өгөх (Захиалга хянах-ын extension)
  void rateOrder(Order o, int stars, String comment) {
    for (final line in o.lines) {
      productById(line.productId)?.reviews.add(
            Review(
                userName: currentUser?.name ?? 'Хэрэглэгч',
                stars: stars,
                comment: comment),
          );
    }
    o.rated = true;
    notifyListeners();
  }

  // ---------------- Гомдол ----------------

  /// Use case: Гомдол мэдүүлэх (Захиалга хянах-ын extension)
  void fileComplaint(Order o, String text) {
    complaints.insert(
      0,
      Complaint(
        id: _nextId('C-'),
        orderId: o.id,
        buyerId: o.buyerId,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Complaint? complaintOf(String orderId) =>
      complaints.where((c) => c.orderId == orderId).firstOrNull;

  /// Use case: Гомдол шийдвэрлэх (Админ)
  void resolveComplaint(Complaint c, String resolution) {
    c
      ..status = ComplaintStatus.resolved
      ..resolution = resolution;
    notifyListeners();
  }

  // ---------------- Чат ----------------

  String chatKey(String buyerId, String storeId) => '$buyerId|$storeId';

  List<ChatMessage> chatOf(String buyerId, String storeId) =>
      chats[chatKey(buyerId, storeId)] ?? const [];

  /// Use case: Дэлгүүртэй холбогдох / Хэрэглэгчтэй холбогдох
  void sendMessage(String buyerId, String storeId, String text,
      {required bool fromBuyer}) {
    chats.putIfAbsent(chatKey(buyerId, storeId), () => []).add(
          ChatMessage(fromBuyer: fromBuyer, text: text, at: DateTime.now()),
        );
    notifyListeners();
  }

  List<String> buyersChattingWith(String storeId) => chats.keys
      .where((k) => k.endsWith('|$storeId'))
      .map((k) => k.split('|').first)
      .toList();

  // ---------------- Дэлгүүр /Merch ----------------

  Store? storeOfOwner(String ownerId) =>
      stores.where((s) => s.ownerId == ownerId).firstOrNull;

  /// Use case: Дэлгүүр үүсгэх, хянах
  Store createStore(
      {required String name,
      required String description,
      required String category}) {
    final s = Store(
      id: _nextId('s'),
      name: name,
      ownerId: currentUser!.id,
      description: description,
      category: category,
    );
    stores.add(s);
    notifyListeners();
    return s;
  }

  void updateStore(Store s,
      {required String name,
      required String description,
      required String category}) {
    s
      ..name = name
      ..description = description
      ..category = category;
    notifyListeners();
  }

  /// Use case: Бараа нэмэх, засах, устгах
  void saveProduct({
    Product? existing,
    required String storeId,
    required String name,
    required String category,
    required int price,
    required int stock,
    required String description,
    int discount = 0,
  }) {
    if (existing != null) {
      existing
        ..name = name
        ..category = category
        ..price = price
        ..discountPercent = discount.clamp(0, 90)
        ..stock = stock
        ..description = description;
    } else {
      // Шинэ бараа админы хяналтаар (Бүтээгдэхүүн хянах) орсны дараа харагдана.
      products.add(Product(
        id: _nextId('p'),
        storeId: storeId,
        name: name,
        category: category,
        price: price,
        stock: stock,
        description: description,
        discountPercent: discount.clamp(0, 90),
        approved: false,
      ));
    }
    notifyListeners();
  }

  void deleteProduct(Product p) {
    products.remove(p);
    cart.removeWhere((c) => c.product.id == p.id);
    notifyListeners();
  }

  /// Use case: Үнэ болон урамшуулал удирдах
  void setPricing(Product p, {required int price, required int discount}) {
    p
      ..price = price
      ..discountPercent = discount.clamp(0, 90);
    notifyListeners();
  }

  // ---------------- Админ ----------------

  /// Use case: Бүтээгдэхүүн хянах
  void setProductApproved(Product p, bool approved) {
    p.approved = approved;
    notifyListeners();
  }

  /// Use case: Дэлгүүр баталгаажуулах
  void setStoreVerified(Store s, bool verified) {
    s.verified = verified;
    notifyListeners();
  }

  int get totalRevenue => orders
      .where((o) => o.status != OrderStatus.cancelled)
      .fold(0, (s, o) => s + o.total);

  Map<String, int> revenueByStore() {
    final map = <String, int>{};
    for (final o in orders.where((o) => o.status != OrderStatus.cancelled)) {
      final name = storeById(o.storeId).name;
      map[name] = (map[name] ?? 0) + o.total;
    }
    return map;
  }

  Map<String, int> unitsByProduct(String storeId) {
    final map = <String, int>{};
    for (final o in ordersOfStore(storeId)
        .where((o) => o.status != OrderStatus.cancelled)) {
      for (final l in o.lines) {
        map[l.productName] = (map[l.productName] ?? 0) + l.quantity;
      }
    }
    return map;
  }

  // ---------------- Хүргэлт ----------------

  List<Order> get availableDeliveries => orders
      .where((o) =>
          o.status == OrderStatus.readyForDelivery && o.courierId == null)
      .toList();

  List<Order> deliveriesOf(String courierId) =>
      orders.where((o) => o.courierId == courierId).toList();

  /// Use case: Хүргэлт хүлээн авах
  void acceptDelivery(Order o) {
    o.courierId = currentUser!.id;
    setOrderStatus(o, OrderStatus.courierAccepted);
  }

  /// Use case: Хүргэлт хуваарилах
  void scheduleDelivery(Order o, String slot) {
    o.deliverySlot = slot;
    setOrderStatus(o, OrderStatus.scheduled);
  }

  /// Use case: Хүргэлт баталгаажуулах (`<<include>>` Хүргэлтийн төлөв шинэчлэх)
  void confirmDelivery(Order o, String receivedBy) {
    o.receivedBy = receivedBy;
    setOrderStatus(o, OrderStatus.delivered);
  }

  // ---------------- Жишээ өгөгдөл ----------------

  void _seed() {
    users.addAll([
      AppUser(
          id: 'u1',
          name: 'Болд',
          phone: '99112233',
          email: 'bold@example.com',
          address: 'БЗД, 13-р хороо, 45-р байр',
          role: UserRole.buyer),
      AppUser(
          id: 'u2',
          name: 'Сараа',
          phone: '88112233',
          address: 'СБД, 1-р хороо',
          role: UserRole.buyer),
      AppUser(
          id: 'm1', name: 'Номин Тех', phone: '77001100', role: UserRole.merchant),
      AppUser(
          id: 'm2', name: 'Гоо Хувцас', phone: '77002200', role: UserRole.merchant),
      AppUser(
          id: 'm3', name: 'Шинэ Ном', phone: '77003300', role: UserRole.merchant),
      AppUser(id: 'a1', name: 'Админ', phone: '70000000', role: UserRole.admin),
      AppUser(
          id: 'c1', name: 'Хүргэгч Ганаа', phone: '95556677', role: UserRole.courier),
      AppUser(
          id: 'c2', name: 'Хүргэгч Тэмүүлэн', phone: '95558899', role: UserRole.courier),
    ]);

    stores.addAll([
      Store(
          id: 's1',
          name: 'Номин Тех',
          ownerId: 'm1',
          description: 'Гар утас, чихэвч, электрон бараа',
          category: 'Электрон',
          verified: true),
      Store(
          id: 's2',
          name: 'Гоо Хувцас',
          ownerId: 'm2',
          description: 'Эрэгтэй, эмэгтэй хувцас, гутал',
          category: 'Хувцас',
          verified: true),
      Store(
          id: 's3',
          name: 'Шинэ Ном',
          ownerId: 'm3',
          description: 'Ном, бичиг хэрэг',
          category: 'Ном',
          verified: false),
    ]);

    products.addAll([
      Product(
          id: 'p1',
          storeId: 's1',
          name: 'Ухаалаг утас X12',
          category: 'Электрон',
          price: 1250000,
          stock: 12,
          discountPercent: 10,
          description: '6.5" дэлгэц, 128GB санах ой, 5000mAh батерей.',
          reviews: [
            Review(userName: 'Сараа', stars: 5, comment: 'Маш сайн утас!'),
          ]),
      Product(
          id: 'p2',
          storeId: 's1',
          name: 'Утасгүй чихэвч',
          category: 'Электрон',
          price: 180000,
          stock: 30,
          description: 'Bluetooth 5.3, дуу чимээ тусгаарлагчтай.'),
      Product(
          id: 'p3',
          storeId: 's1',
          name: 'Ухаалаг цаг',
          category: 'Электрон',
          price: 320000,
          stock: 8,
          description: 'Зүрхний цохилт, алхам тоолуур, ус нэвтрэхгүй.'),
      Product(
          id: 'p4',
          storeId: 's2',
          name: 'Ноолууран цамц',
          category: 'Хувцас',
          price: 240000,
          stock: 15,
          discountPercent: 20,
          description: '100% монгол ноолуур.',
          reviews: [
            Review(userName: 'Болд', stars: 4, comment: 'Дулаахан, чанартай.'),
          ]),
      Product(
          id: 'p5',
          storeId: 's2',
          name: 'Пүүз',
          category: 'Хувцас',
          price: 159000,
          stock: 20,
          description: 'Хөнгөн, спорт пүүз.'),
      Product(
          id: 'p6',
          storeId: 's2',
          name: 'Өвлийн хүрэм',
          category: 'Хувцас',
          price: 390000,
          stock: 5,
          approved: false,
          description: 'Админы хяналт хүлээж буй бараа.'),
      Product(
          id: 'p7',
          storeId: 's3',
          name: 'Монголын нууц товчоо',
          category: 'Ном',
          price: 35000,
          stock: 40,
          description: 'Дэлгүүр баталгаажаагүй тул хайлтад гарахгүй.'),
    ]);

    final o1 = Order(
      id: 'ORD-001',
      buyerId: 'u1',
      storeId: 's1',
      address: users.first.address,
      paymentMethod: PaymentMethod.qpay,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: OrderStatus.delivered,
      lines: [
        OrderLine(
            productId: 'p2',
            productName: 'Утасгүй чихэвч',
            unitPrice: 180000,
            quantity: 1),
      ],
    )
      ..courierId = 'c1'
      ..receivedBy = 'Болд';
    final o2 = Order(
      id: 'ORD-002',
      buyerId: 'u1',
      storeId: 's2',
      address: users.first.address,
      paymentMethod: PaymentMethod.card,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      status: OrderStatus.readyForDelivery,
      lines: [
        OrderLine(
            productId: 'p4',
            productName: 'Ноолууран цамц',
            unitPrice: 192000,
            quantity: 2),
      ],
    );
    final o3 = Order(
      id: 'ORD-003',
      buyerId: 'u2',
      storeId: 's1',
      address: 'СБД, 1-р хороо',
      paymentMethod: PaymentMethod.socialPay,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      lines: [
        OrderLine(
            productId: 'p1',
            productName: 'Ухаалаг утас X12',
            unitPrice: 1125000,
            quantity: 1),
      ],
    );
    orders.addAll([o3, o2, o1]);

    complaints.add(Complaint(
      id: 'C-001',
      orderId: 'ORD-001',
      buyerId: 'u1',
      text: 'Хайрцаг нь бага зэрэг гэмтэлтэй ирсэн.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ));

    chats[chatKey('u1', 's1')] = [
      ChatMessage(
          fromBuyer: true,
          text: 'Сайн байна уу, X12 утас өөр өнгөөр байгаа юу?',
          at: DateTime.now().subtract(const Duration(hours: 2))),
      ChatMessage(
          fromBuyer: false,
          text: 'Сайн байна уу! Хар, цэнхэр өнгөтэй байгаа.',
          at: DateTime.now().subtract(const Duration(hours: 1))),
    ];
  }
}

/// AppState-г widget мод руу дамжуулах энгийн InheritedNotifier.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Callback дотор (build-ээс гадуур) ашиглах, сонсохгүй хувилбар.
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
