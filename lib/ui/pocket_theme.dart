import 'package:flutter/material.dart';

abstract final class PocketColors {
  static const cream = Color(0xFFFFF8ED);
  static const ink = Color(0xFF40342E);
  static const muted = Color(0xFF806D5C);
  static const red = Color(0xFFED6258);
  static const redDepth = Color(0xFFC6413A);
  static const tile = Color(0xFFF0E6D6);
  static const tileDepth = Color(0xFFDDCEBA);
  static const buttonInk = Color(0xFFFFFAF4);
}

abstract final class PocketType {
  static const title = TextStyle(
    fontFamily: 'Fredoka',
    fontSize: 29,
    fontWeight: FontWeight.w500,
    height: 1.18,
    letterSpacing: -.7,
    color: PocketColors.ink,
  );
  static const body = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.55,
    color: PocketColors.muted,
  );
}

ThemeData pocketTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: 'Nunito',
  scaffoldBackgroundColor: PocketColors.cream,
  colorScheme: ColorScheme.fromSeed(seedColor: PocketColors.red).copyWith(
    primary: PocketColors.red,
    onPrimary: PocketColors.ink,
    surface: PocketColors.cream,
    onSurface: PocketColors.ink,
    secondary: PocketColors.tile,
  ),
  textTheme: const TextTheme(bodyMedium: PocketType.body),
  iconTheme: const IconThemeData(color: PocketColors.muted, size: 21),
  splashFactory: NoSplash.splashFactory,
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: PocketColors.cream,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
  ),
);
