import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green.shade800,
    brightness: Brightness.light,
    primary: Colors.green.shade800,
    secondary: Colors.green.shade600,
    tertiary: Colors.green.shade400,
    surface: Colors.green.shade50,
    onSurface: Colors.green.shade900,
  ),
);
