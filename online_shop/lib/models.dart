// Онлайн дэлгүүрийн өгөгдлийн загварууд (use case диаграмд тулгуурласан).

enum UserRole { guest, buyer, merchant, admin, courier }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
        UserRole.guest => 'Зочин',
        UserRole.buyer => 'Худалдан авагч',
        UserRole.merchant => 'Дэлгүүр /Merch',
        UserRole.admin => 'Админ',
        UserRole.courier => 'Хүргэлт',
      };
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.email = '',
    this.address = '',
  });

  final String id;
  String name;
  String phone;
  String email;
  String address;
  final UserRole role;
}

class Store {
  Store({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.description,
    required this.category,
    this.verified = false,
  });

  final String id;
  String name;
  final String ownerId;
  String description;
  String category;
  bool verified;
}

class Review {
  Review({required this.userName, required this.stars, required this.comment});

  final String userName;
  final int stars;
  final String comment;
}

class Product {
  Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.description,
    this.discountPercent = 0,
    this.approved = true,
    List<Review>? reviews,
  }) : reviews = reviews ?? [];

  final String id;
  final String storeId;
  String name;
  String category;
  int price;
  int stock;
  String description;
  int discountPercent;
  bool approved;
  final List<Review> reviews;

  int get finalPrice => (price * (100 - discountPercent) / 100).round();

  double get rating => reviews.isEmpty
      ? 0
      : reviews.map((r) => r.stars).reduce((a, b) => a + b) / reviews.length;
}

class CartItem {
  CartItem(this.product, this.quantity);

  final Product product;
  int quantity;

  int get total => product.finalPrice * quantity;
}

enum OrderStatus {
  paid,
  processing,
  readyForDelivery,
  courierAccepted,
  scheduled,
  onTheWay,
  delivered,
  cancelled,
}

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.paid => 'Төлбөр төлөгдсөн',
        OrderStatus.processing => 'Дэлгүүр боловсруулж байна',
        OrderStatus.readyForDelivery => 'Хүргэлтэд бэлэн',
        OrderStatus.courierAccepted => 'Хүргэгч хүлээн авсан',
        OrderStatus.scheduled => 'Хүргэлт хуваарилагдсан',
        OrderStatus.onTheWay => 'Замд явж байна',
        OrderStatus.delivered => 'Хүргэгдсэн',
        OrderStatus.cancelled => 'Цуцлагдсан',
      };
}

enum PaymentMethod { card, qpay, socialPay }

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.card => 'Банкны карт',
        PaymentMethod.qpay => 'QPay',
        PaymentMethod.socialPay => 'SocialPay',
      };
}

class OrderLine {
  OrderLine({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String productName;
  final int unitPrice;
  final int quantity;

  int get total => unitPrice * quantity;
}

class Order {
  Order({
    required this.id,
    required this.buyerId,
    required this.storeId,
    required this.lines,
    required this.address,
    required this.paymentMethod,
    required this.createdAt,
    this.status = OrderStatus.paid,
  });

  final String id;
  final String buyerId;
  final String storeId;
  final List<OrderLine> lines;
  final String address;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  OrderStatus status;
  String? courierId;
  String? deliverySlot;
  String? receivedBy;
  bool rated = false;
  final List<DateTime> history = [];

  int get total => lines.fold(0, (sum, l) => sum + l.total);
}

enum ComplaintStatus { open, resolved }

class Complaint {
  Complaint({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String buyerId;
  final String text;
  final DateTime createdAt;
  ComplaintStatus status = ComplaintStatus.open;
  String? resolution;
}

class ChatMessage {
  ChatMessage({required this.fromBuyer, required this.text, required this.at});

  final bool fromBuyer;
  final String text;
  final DateTime at;
}
