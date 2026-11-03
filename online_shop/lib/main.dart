import 'package:flutter/material.dart';

import 'app_state.dart';
import 'models.dart';
import 'screens/admin_screens.dart';
import 'screens/buyer_screens.dart';
import 'screens/courier_screens.dart';
import 'screens/login_screen.dart';
import 'screens/merchant_screens.dart';

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
          useMaterial3: true,
        ),
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
    if (app.isGuest) return const BuyerHome(key: ValueKey('guest'));
    final user = app.currentUser;
    if (user == null) return const LoginScreen();
    return switch (user.role) {
      UserRole.buyer || UserRole.guest => BuyerHome(key: ValueKey(user.id)),
      UserRole.merchant => MerchantHome(key: ValueKey(user.id)),
      UserRole.admin => const AdminHome(),
      UserRole.courier => CourierHome(key: ValueKey(user.id)),
    };
  }
}
