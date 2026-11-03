import 'package:flutter_test/flutter_test.dart';

import 'package:online_shop/app_state.dart';
import 'package:online_shop/main.dart';
import 'package:online_shop/models.dart';

void main() {
  testWidgets('Login screen shows every role', (tester) async {
    await tester.pumpWidget(OnlineShopApp(state: AppState()));
    for (final role in UserRole.values) {
      expect(find.text(role.label), findsOneWidget);
    }
  });

  testWidgets('Guest can browse products', (tester) async {
    final state = AppState();
    await tester.pumpWidget(OnlineShopApp(state: state));
    await tester.tap(find.text(UserRole.guest.label));
    await tester.pumpAndSettle();
    expect(find.text('Ухаалаг утас X12'), findsOneWidget);
    // Баталгаажаагүй дэлгүүрийн бараа харагдахгүй.
    expect(find.text('Монголын нууц товчоо'), findsNothing);
  });

  test('Order flows from buyer to store to courier', () {
    final s = AppState();
    s.loginAs(s.users.firstWhere((u) => u.id == 'u2'));
    s.addToCart(s.productById('p2')!, 2);
    final order = s.placeOrder(address: 'Хаяг', method: PaymentMethod.qpay).single;
    expect(order.total, 360000);
    expect(s.cart, isEmpty);

    s.setOrderStatus(order, OrderStatus.processing);
    s.setOrderStatus(order, OrderStatus.readyForDelivery);
    expect(s.availableDeliveries, contains(order));

    s.loginAs(s.users.firstWhere((u) => u.id == 'c1'));
    s.acceptDelivery(order);
    s.scheduleDelivery(order, 'Өнөөдөр 10:00–12:00');
    s.setOrderStatus(order, OrderStatus.onTheWay);
    s.confirmDelivery(order, 'Сараа');
    expect(order.status, OrderStatus.delivered);
  });
}
