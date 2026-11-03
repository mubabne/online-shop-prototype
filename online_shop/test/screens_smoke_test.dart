import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:online_shop/app_state.dart';
import 'package:online_shop/main.dart';

/// Дүр бүрээр нэвтэрч, бүх табыг нээгээд layout алдаа гарахгүйг шалгана.
void main() {
  Future<AppState> start(WidgetTester tester, String userId) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final state = AppState();
    await tester.pumpWidget(OnlineShopApp(state: state));
    state.loginAs(state.users.firstWhere((u) => u.id == userId));
    await tester.pumpAndSettle();
    return state;
  }

  Future<void> visitTabs(WidgetTester tester, List<String> labels) async {
    for (final label in labels) {
      await tester.tap(find.descendant(
          of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('Buyer screens render', (tester) async {
    final state = await start(tester, 'u1');
    state.addToCart(state.productById('p1')!);
    await tester.pumpAndSettle();
    await visitTabs(tester, ['Дэлгүүр', 'Сагс', 'Захиалга', 'Профайл', 'Нүүр']);

    await tester.tap(find.text('Утасгүй чихэвч').first);
    await tester.pumpAndSettle();
    expect(find.text('Үнэлгээ, сэтгэгдэл'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await visitTabs(tester, ['Захиалга']);
    await tester.tap(find.textContaining('ORD-001'));
    await tester.pumpAndSettle();
    expect(find.text('Хүргэлтийн явц'), findsOneWidget);
  });

  testWidgets('Store screens render', (tester) async {
    await start(tester, 'm1');
    await visitTabs(tester, ['Бараа', 'Захиалга', 'Тайлан', 'Чат', 'Дэлгүүр']);
  });

  testWidgets('Courier screens render', (tester) async {
    await start(tester, 'c1');
    await tester.tap(find.text('Хүргэлт хүлээн авах'));
    await tester.pumpAndSettle();
    await visitTabs(tester, ['Миний хүргэлт']);
    expect(find.text('Хүргэлт хуваарилах'), findsOneWidget);
  });

  testWidgets('Admin screens render', (tester) async {
    await start(tester, 'a1');
    await visitTabs(tester, ['Бүтээгдэхүүн', 'Дэлгүүр', 'Гомдол', 'Тайлан']);
  });
}
