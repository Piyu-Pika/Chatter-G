import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../login_page/login_page.dart';
import '../../providers/auth_provider.dart'; // Import Auth Provider
import '../home_screen/home_screen.dart'; // Import Home Screen

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen(); // User logged in
        } else {
          return LoginPage(); // User logged out
        }
      },
      loading: () => const Scaffold(
        body: Center(
            child: CircularProgressIndicator()), // Show loading indicator
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Something went wrong: $error')), // Show error
      ),
    );
  }
}

class Splashscreen extends ConsumerStatefulWidget {
  const Splashscreen({super.key});

  @override
  ConsumerState<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends ConsumerState<Splashscreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash screen duration AND for the initial auth state to resolve
    await Future.delayed(const Duration(seconds: 3));

    // Check the initial auth state after the delay
    // The authStateChangesProvider might still be loading initially,
    // but navigating to AuthWrapper handles all states (data, loading, error).
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Using MediaQuery to make image size relative if desired
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // Ensure appTheme and splashColor are correctly defined
      body: Container(
        decoration: BoxDecoration(
          gradient: context
              .backgroundGradient, // Use the gradient defined in app_theme.dart
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Consider making the image larger for a splash screen
              Image.asset(
                'assets/images/chatter-g.jpg', // Ensure this path is correct in pubspec.yaml
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
      ),
    );
  }
}
