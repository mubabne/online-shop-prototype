import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'screens/admin_screens.dart';
import 'screens/buyer_screens.dart';
import 'screens/courier_screens.dart';
import 'screens/login_screen.dart';
import 'screens/merchant_screens.dart';
import 'theme.dart';

void main() {
  runApp(OnlineShopApp(state: AppState()));
}

class OnlineShopApp extends StatelessWidget {
  const OnlineShopApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Онлайн дэлгүүр',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const RoleRouter(),
      ),
    );
  }
}

/// Нэвтэрсэн хэрэглэгчийн дүрээс хамааран үндсэн дэлгэцийг сонгоно.
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.currentUser;
    final Widget page;
    if (app.isGuest) {
      page = const BuyerHome(key: ValueKey('guest'));
    } else if (user == null) {
      page = const LoginScreen(key: ValueKey('login'));
    } else {
      page = switch (user.role) {
        UserRole.buyer || UserRole.guest => BuyerHome(key: ValueKey(user.id)),
        UserRole.merchant => MerchantHome(key: ValueKey(user.id)),
        UserRole.admin => const AdminHome(key: ValueKey('admin')),
        UserRole.courier => CourierHome(key: ValueKey(user.id)),
      };
    }
    // Нэвтрэх / гарах үед зөөлөн шилжилт.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.97, end: 1.0).animate(anim),
          child: child,
        ),
      ),
      child: page,
    );
  }
}
