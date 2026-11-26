import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF111111);
  static const body = Color(0xFF1C1C1C);
  static const caption = Color(0xFF6E6E6E);
  static const hint = Color(0xFF9A9A9A);
  static const line = Color(0xFFE4E4E4);
  static const today = Color(0xFFE6E6E6);
  static const outsideDay = Color(0xFFC8C8C8);
  static const weekday = Color(0xFFB0B0B0);
  static const field = Color(0xFFF4F4F4);
  static const canvas = Color(0xFFE8E8E8);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'NotoSansKR',
    scaffoldBackgroundColor: Colors.white,
    splashColor: const Color(0x14000000),
    highlightColor: const Color(0x0A000000),
    colorScheme: const ColorScheme.light(
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.ink,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.ink,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'NotoSansKR',
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSansKR',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'NotoSansKR',
        fontSize: 14,
        height: 1.45,
        color: AppColors.body,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      dragHandleColor: Color(0xFFD5D5D5),
      dragHandleSize: Size(36, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        textStyle: const TextStyle(
          fontFamily: 'NotoSansKR',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
