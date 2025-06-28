// filepath: d:\ChatterG\lib\core\routers\router.dart
// Creating router for the app screens

import 'package:flutter/material.dart';
import '../../presentation/pages/home_screen/home_screen.dart';
import '../../presentation/pages/login_page/login_page.dart';
import '../../presentation/pages/onboarding_chat_screen/onboarding_chat_screen.dart';
import '../../presentation/pages/profile_screen/ProfileScreen.dart';
import '../../presentation/pages/signup_page/signup_page.dart';
import '../../presentation/pages/splashscreen/splashscreen.dart';
import '../../presentation/pages/chat_screen/chat_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const Splashscreen(),
  '/login': (context) => LoginPage(),
  '/signup': (context) => const SignupPage(),
  '/home': (context) => const HomeScreen(),
  '/chat': (context) => const ChatScreen(),
  '/profile': (context) => const ProfileScreen(),
  '/onboarding': (context) => const OnboardingChatScreen(),
  // Add more routes as needed
  // '/settings': (context) => const SettingsScreen(),
  // '/about': (context) => const AboutScreen(),
  // '/terms': (context) => const TermsScreen(),
  // '/privacy': (context) => const PrivacyScreen(),
  // '/camera': (context) => const CameraScreen(),
  // 'call': (context) => const CallScreen(),
  // '/chatterg-memes': (context) => const ChatterGMemesScreen(),
};
