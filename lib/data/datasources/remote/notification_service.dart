import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatterg/data/models/user_model.dart';

import 'api_value.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static AppUser? _currentUser;
  static String? _authToken;

  // Initialize with just Firebase user - for splash screen
  static Future<void> initializeBasic() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _sendFcmTokenToServer(); // Send token even without AppUser
    _listenToForegroundMessages();
    _listenToTokenRefresh();
  }

  // Full initialization with AppUser - for login
  static Future<void> initialize(AppUser user, {required String authToken}) async {
    _currentUser = user;
    _authToken = authToken;

    await _requestPermission();
    await _initLocalNotifications();
    await _sendFcmTokenToServer();
    _listenToForegroundMessages();
    _listenToTokenRefresh();
  }

  static Future<void> _requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined or has not accepted permission');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _localNotifications.initialize(initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap);
  }

  static Future<void> _sendFcmTokenToServer() async {
    try {
      String? token = await _fcm.getToken();
      if (token == null) {
        debugPrint('FCM token is null');
        return;
      }

      // Get Firebase user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        debugPrint('No Firebase user found, cannot send FCM token');
        return;
      }

      final apiClient = ApiClient();
      await apiClient.updateFcmToken(firebaseUser.uid, token);
      debugPrint('FCM token updated successfully on server');
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
    }
  }

  static void _listenToTokenRefresh() {
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('FCM token refreshed: $newToken');
      await _sendFcmTokenToServer();
    });
  }

  static void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.messageId}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _onNotificationTapFromMessage(message);
    });
  }

  static void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chatterg_channel',
          'ChatterG Messages',
          channelDescription: 'Notification channel for chat messages',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  static void _onNotificationTapFromMessage(RemoteMessage message) {
    _handleNotificationNavigation(message.data);
  }

  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final senderId = data['sender_id'];
    if (senderId != null) {
      debugPrint('Navigate to chat screen for sender: $senderId');
      // TODO: Integrate NavigationService or Riverpod to open ChatScreen
    }
  }
}