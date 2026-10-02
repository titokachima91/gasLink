import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  const orange = Color(0xFFF57C00);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: orange),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: orange,
      foregroundColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: orange,
        minimumSize: const Size.fromHeight(52),
      ),
    ),
  );
}
