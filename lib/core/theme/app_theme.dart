import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    // Primary color - deep blue from the icon background
    primary: const Color.fromRGBO(88, 86, 214, 1.0),
    onPrimary: Colors.white,
    // Secondary color - vibrant orange from the speech bubble
    secondary: const Color.fromRGBO(255, 133, 102, 1.0),
    onSecondary: Colors.white,
    // Tertiary color - light blue for accents
    tertiary: const Color.fromRGBO(135, 206, 250, 1.0),
    onTertiary: const Color.fromRGBO(32, 32, 96, 1.0),
    // Surface colors - using light blue tints
    surface: const Color.fromRGBO(248, 250, 255, 1.0),
    onSurface: const Color.fromRGBO(32, 32, 96, 0.9),
    // Error colors
    error: const Color.fromRGBO(244, 67, 54, 1.0),
    onError: Colors.white,
    // Container colors
    surfaceContainerHighest: const Color.fromRGBO(135, 206, 250, 0.15),
    onSurfaceVariant: const Color.fromRGBO(88, 86, 214, 1.0),
    outline: const Color.fromRGBO(135, 206, 250, 0.5),
    outlineVariant: const Color.fromRGBO(135, 206, 250, 0.3),
    shadow: Colors.black26,
    scrim: Colors.black54,
    inverseSurface: const Color.fromRGBO(88, 86, 214, 1.0),
    onInverseSurface: Colors.white,
    inversePrimary: const Color.fromRGBO(135, 206, 250, 1.0),
    surfaceTint: const Color.fromRGBO(135, 206, 250, 0.1),
  ),
  // Typography and text theme
  textTheme: TextTheme(
    displayLarge: TextStyle(color: const Color.fromRGBO(88, 86, 214, 1.0)),
    displayMedium: TextStyle(color: const Color.fromRGBO(88, 86, 214, 1.0)),
    displaySmall: TextStyle(color: const Color.fromRGBO(88, 86, 214, 1.0)),
    headlineLarge: TextStyle(color: const Color.fromRGBO(88, 86, 214, 1.0)),
    headlineMedium: TextStyle(color: const Color.fromRGBO(88, 86, 214, 1.0)),
    headlineSmall: TextStyle(color: const Color.fromRGBO(88, 86, 214, 1.0)),
    titleLarge: TextStyle(
        color: const Color.fromRGBO(88, 86, 214, 1.0),
        fontWeight: FontWeight.bold),
    titleMedium: TextStyle(color: const Color.fromRGBO(88, 86, 214, 1.0)),
    titleSmall: TextStyle(color: const Color.fromRGBO(88, 86, 214, 1.0)),
    bodyLarge: TextStyle(color: const Color.fromRGBO(32, 32, 96, 0.87)),
    bodyMedium: TextStyle(color: const Color.fromRGBO(32, 32, 96, 0.87)),
    bodySmall: TextStyle(color: const Color.fromRGBO(32, 32, 96, 0.54)),
    labelLarge: TextStyle(color: Colors.white),
    labelMedium: TextStyle(color: Colors.white),
    labelSmall: TextStyle(color: Colors.white),
  ),
  // Button theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      disabledBackgroundColor: const Color.fromRGBO(135, 206, 250, 0.5),
      backgroundColor: const Color.fromRGBO(88, 86, 214, 1.0),
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  // Icon theme
  iconTheme: IconThemeData(
    color: const Color.fromRGBO(255, 133, 102, 1.0),
    size: 24.0,
  ),
  // Card theme
  cardTheme: CardThemeData(
    color: const Color.fromRGBO(248, 250, 255, 1.0),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
);

// Extension for common gradients using our theme colors
extension GradientExtensions on BuildContext {
  // Background gradient mimicking the icon's blue gradient
  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromRGBO(135, 206, 250, 0.8), // Light blue
          const Color.fromRGBO(100, 149, 237, 0.9), // Cornflower blue
          const Color.fromRGBO(88, 86, 214, 1.0), // Deep blue
        ],
      );

  // Button gradient for elevated components
  LinearGradient get buttonGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color.fromRGBO(88, 86, 214, 1.0), // Deep blue
          const Color.fromRGBO(100, 149, 237, 1.0), // Cornflower blue
        ],
      );

  // Orange accent gradient for chat bubbles or special elements
  LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color.fromRGBO(255, 165, 102, 1.0), // Light orange
          const Color.fromRGBO(255, 133, 102, 1.0), // Main orange
        ],
      );

  // Chat bubble gradient (orange like in the icon)
  LinearGradient get chatBubbleGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color.fromRGBO(255, 165, 102, 1.0), // Light orange
          const Color.fromRGBO(255, 133, 102, 1.0), // Main orange
          const Color.fromRGBO(255, 99, 71, 1.0), // Coral orange
        ],
      );
}

// // Example usage of the gradient backgrounds
// class GradientContainer extends StatelessWidget {
//   final Widget child;

//   const GradientContainer({Key? key, required this.child}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: context.backgroundGradient,
//       ),
//       child: child,
//     );
//   }
// }

// class GradientButton extends StatelessWidget {
//   final VoidCallback onPressed;
//   final String text;

//   const GradientButton({Key? key, required this.onPressed, required this.text})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: context.buttonGradient,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.transparent,
//           shadowColor: Colors.transparent,
//           elevation: 0,
//         ),
//         child: Text(text),
//       ),
//     );
//   }
// }

// // New: Chat bubble widget matching the icon's speech bubble
// class ChatBubble extends StatelessWidget {
//   final String message;
//   final bool isUser;

//   const ChatBubble({Key? key, required this.message, this.isUser = false})
//       : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         gradient: isUser
//             ? context.chatBubbleGradient
//             : context.buttonGradient,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Text(
//         message,
//         style: TextStyle(
//           color: Colors.white,
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }
// }
