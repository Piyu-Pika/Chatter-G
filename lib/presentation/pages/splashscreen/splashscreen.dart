import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../login_page/login_page.dart';
// Assuming you have a home screen defined elsewhere, e.g., 'home_screen.dart'
// import 'package:godzilla/presentation/screens/home_screen.dart';

// Placeholder for HomeScreen if not defined
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: const Center(child: Text('Welcome to GoDZilla!')),
    );
  }
}

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Simulate a delay for loading resources, checking auth, etc.
    await Future.delayed(const Duration(seconds: 3));

    // Ensure the widget is still mounted before navigating
    if (mounted) {
      // Replace the splash screen with the home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const LoginPage()), // Navigate to your actual home screen
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using MediaQuery to make image size relative if desired
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: appTheme
          .splashColor, // Ensure appTheme and splashColor are correctly defined
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Consider making the image larger for a splash screen
            Image.asset(
              'assets/images/godzilla.png', // Ensure this path is correct in pubspec.yaml
              height: screenHeight * 0.2, // Example: 20% of screen height
              width: screenWidth * 0.4, // Example: 40% of screen width
              fit: BoxFit.contain, // Adjust fit as needed
            ),
            const SizedBox(height: 30),
            Text(
              'GodZilla',
              style: TextStyle(
                fontSize: 32, // Slightly larger font size
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary, // Use theme color for better adaptability
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 40), // Space before the progress indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withOpacity(0.8), // Use theme color
              ),
              strokeWidth: 3.0,
            ),
          ],
        ),
      ),
    );
  }
}
