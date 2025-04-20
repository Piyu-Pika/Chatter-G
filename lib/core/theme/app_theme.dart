import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    // Primary color - used for app bar, buttons, etc.
    primary: const Color.fromRGBO(37, 169, 153, 1.0),
    onPrimary: Colors.white,
    // Secondary color - used for floating action buttons, selection controls
    secondary: const Color.fromRGBO(94, 229, 188, 1.0),
    onSecondary: Colors.black,
    // Tertiary color - used for emphasis
    tertiary: const Color.fromRGBO(133, 255, 186, 1.0),
    onTertiary: Colors.black,
    // Background colors
    background: Colors.white,
    onBackground: Colors.black87,
    // Surface colors - used for cards, sheets, menus
    surface: Colors.white,
    onSurface: const Color.fromRGBO(37, 169, 153, 0.9),
    // Error colors
    error: Colors.redAccent,
    onError: Colors.white,
    // Container colors
    surfaceVariant: const Color.fromRGBO(133, 255, 186, 0.15),
    onSurfaceVariant: const Color.fromRGBO(37, 169, 153, 1.0),
    outline: const Color.fromRGBO(94, 229, 186, 0.5),
    outlineVariant: const Color.fromRGBO(94, 229, 188, 0.3),
    shadow: Colors.black26,
    scrim: Colors.black54,
    inverseSurface: const Color.fromRGBO(37, 169, 153, 1.0),
    onInverseSurface: Colors.white,
    inversePrimary: const Color.fromRGBO(133, 255, 186, 1.0),
    surfaceTint: const Color.fromRGBO(94, 229, 188, 0.1),
  ),
  // Typography and text theme
  textTheme: TextTheme(
    displayLarge: TextStyle(color: const Color.fromRGBO(37, 169, 153, 1.0)),
    displayMedium: TextStyle(color: const Color.fromRGBO(37, 169, 153, 1.0)),
    displaySmall: TextStyle(color: const Color.fromRGBO(37, 169, 153, 1.0)),
    headlineLarge: TextStyle(color: const Color.fromRGBO(37, 169, 153, 1.0)),
    headlineMedium: TextStyle(color: const Color.fromRGBO(37, 169, 153, 1.0)),
    headlineSmall: TextStyle(color: const Color.fromRGBO(37, 169, 153, 1.0)),
    titleLarge: TextStyle(
        color: const Color.fromRGBO(37, 169, 153, 1.0),
        fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: const Color.fromRGBO(37, 169, 153, 1.0)),
    titleSmall: TextStyle(color: const Color.fromRGBO(37, 169, 153, 1.0)),
    bodyLarge: TextStyle(color: Colors.black87),
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black54),
    labelLarge: TextStyle(color: Colors.white),
    labelMedium: TextStyle(color: Colors.white),
    labelSmall: TextStyle(color: Colors.white),
  ),
  // Button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromRGBO(37, 169, 153, 1.0),
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  // Icon theme
  iconTheme: IconThemeData(
    color: const Color.fromRGBO(94, 229, 188, 1.0),
    size: 24.0,
  ),
  // Card theme
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
);

// Extension for common gradients using our theme colors
extension GradientExtensions on BuildContext {
  // Background gradient for screens or large containers
  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromRGBO(133, 255, 186, 0.7), // Lighter green
          const Color.fromRGBO(94, 229, 188, 0.8), // Medium green
          const Color.fromRGBO(37, 169, 153, 0.9), // Deeper teal
        ],
      );

  // Button gradient for elevated components
  LinearGradient get buttonGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color.fromRGBO(37, 169, 153, 1.0), // Deeper teal
          const Color.fromRGBO(94, 229, 188, 1.0), // Medium green
        ],
      );

  // Accent gradient for highlights or special elements
  LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color.fromRGBO(133, 255, 186, 1.0), // Lighter green
          const Color.fromRGBO(94, 229, 186, 1.0), // Medium green
        ],
      );
}

// Example usage of the gradient backgrounds
class GradientContainer extends StatelessWidget {
  final Widget child;

  const GradientContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: context.backgroundGradient,
      ),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const GradientButton({Key? key, required this.onPressed, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: context.buttonGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
        ),
        child: Text(text),
      ),
    );
  }
}
