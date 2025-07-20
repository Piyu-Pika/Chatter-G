// navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static String? _currentChatUserId;
  
  static void setCurrentChatUser(String? userId) {
    _currentChatUserId = userId;
  }
  
  static String? getCurrentChatUser() {
    return _currentChatUserId;
  }
  
  static bool isInChatWith(String userId) {
    return _currentChatUserId == userId;
  }
  
  static Future<void> navigateToChat(String senderId) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // TODO: Replace with your actual navigation logic
      // Example: Navigator.of(context).pushNamed('/chat', arguments: senderId);
      debugPrint('Navigate to chat with user: $senderId');
    }
  }
}