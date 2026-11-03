import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'models.dart';

/// Аппын өнгө, градиент, загварын нэгдсэн тохиргоо.
class AppColors {
  static const primary = Color(0xFF5B4CF0);
  static const accent = Color(0xFFFF7A59);

  static const brandGradient = LinearGradient(
    colors: [Color(0xFF5B4CF0), Color(0xFF8E5CF7), Color(0xFFFF7A59)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Ангилал бүрийн дүрс ба градиент.
  static (IconData, List<Color>) category(String category) => switch (category) {
        'Электрон' => (
            Icons.devices_other_rounded,
            const [Color(0xFF4F7CFF), Color(0xFF6A5CFF)]
          ),
        'Хувцас' => (
            Icons.checkroom_rounded,
            const [Color(0xFFFF6F91), Color(0xFFFF9671)]
          ),
        'Ном' => (
            Icons.menu_book_rounded,
            const [Color(0xFFB0753F), Color(0xFFE0A458)]
          ),
        _ => (
            Icons.shopping_bag_rounded,
            const [Color(0xFF00B894), Color(0xFF00CEC9)]
          ),
      };

  /// Дүр бүрийн өнгө (нэвтрэх дэлгэц, толгой хэсэг).
  static List<Color> role(UserRole role) => switch (role) {
        UserRole.guest => const [Color(0xFF8E9AAF), Color(0xFFB8C0D6)],
        UserRole.buyer => const [Color(0xFF5B4CF0), Color(0xFF8E5CF7)],
        UserRole.merchant => const [Color(0xFFFF7A59), Color(0xFFFFB86B)],
        UserRole.courier => const [Color(0xFF00B894), Color(0xFF55EFC4)],
        UserRole.admin => const [Color(0xFF2D3561), Color(0xFF5B4CF0)],
      };
}

ThemeData buildTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
    secondary: AppColors.accent,
  );
  final radius = BorderRadius.circular(16);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor:
        light ? const Color(0xFFF6F5FB) : const Color(0xFF121218),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: light ? Colors.white : const Color(0xFF1E1E28),
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light ? Colors.white : const Color(0xFF1E1E28),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide:
            BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      showCheckmark: false,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: light ? Colors.white : const Color(0xFF1A1A22),
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          )),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    }),
  );
}
