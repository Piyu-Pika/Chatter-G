import 'dart:async';
import 'package:chatterg/data/datasources/remote/cockroachdb_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../login_page/login_page.dart';
import '../../providers/auth_provider.dart';
import '../home_screen/home_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          //update the user is now online in the database
          CockroachDBDataSource().updateUserStatus(user.uid, true);
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
  bool _isServerReady = false;
  bool _isTimerComplete = false;

  @override
  void initState() {
    super.initState();
    _startServerAndTimer();
  }

  Future<void> _startServerAndTimer() async {
    // Start both processes simultaneously
    _tryStartingServer();
    _startMinimumTimer();
  }

  // Function to ensure minimum splash display time
  Future<void> _startMinimumTimer() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _isTimerComplete = true;
    });
    _navigateIfReady();
  }

  // Function to start the server
  Future<void> _tryStartingServer() async {
    while (!_isServerReady) {
      try {
        final response =
            await CockroachDBDataSource().Forcefullystartingserver();
        if (response == 200) {
          setState(() {
            _isServerReady = true;
          });
          _navigateIfReady();
          break; // Exit the loop if the response is successful
        }
      } catch (e) {
        // Log the error or handle it
        print('Retrying to start server: $e');
        _isServerReady = true; // Reset the server status
      }
      await Future.delayed(const Duration(seconds: 1)); // Wait before retrying
    }
  }

  // Only navigate when both the server is ready and minimum time has passed
  void _navigateIfReady() {
    if (_isServerReady && _isTimerComplete && mounted) {
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
      body: Container(
        decoration: BoxDecoration(
          gradient: context.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/chatterg3.png',
                height: screenHeight * 0.2,
                width: screenWidth * 0.4,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              Text(
                'Chatter G',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                ),
                strokeWidth: 3.0,
              ),
              const SizedBox(height: 20),
              Text(
                _isServerReady ? "Server connected" : "Connecting to server...",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
