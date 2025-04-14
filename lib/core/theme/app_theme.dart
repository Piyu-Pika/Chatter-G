import 'package:flutter/material.dart';

// Define the application's theme data
final ThemeData appTheme = ThemeData(
    // Use Material 3 design guidelines
    useMaterial3: true,

    // Define the color scheme based on a seed color
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green.shade800,
      // Optionally, define brightness (light/dark)
      brightness: Brightness.light,
    ),

    // Define default Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
      bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
    ),

    // Define other theme properties like AppBarTheme, ButtonTheme, etc.
    appBarTheme: const AppBarTheme(
      color: Colors.blue,
      elevation: 4.0,
    ),
    splashColor: Color.fromARGB(255, 60, 159, 72)

    // Add more customizations as needed
    );
// Define the application's theme data
// final ThemeData appTheme = ThemeData(
//   // Use Material 3 design guidelines
//   useMaterial3: true,

//   // Define the color scheme based on a seed color
//   colorScheme: ColorScheme.fromSeed(
//     seedColor: Colors.deepPurple,
//     // Optionally, define brightness (light/dark)
//     // brightness: Brightness.light,
//   ),

//   // Define default Text Theme
//   // textTheme: const TextTheme(
//   //   displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
//   //   titleLarge: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
//   //   bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
//   // ),

//   // Define other theme properties like AppBarTheme, ButtonTheme, etc.
//   // appBarTheme: const AppBarTheme(
//   //   color: Colors.blue,
//   //   elevation: 4.0,
//   // ),

//   // Add more customizations as needed
// );
