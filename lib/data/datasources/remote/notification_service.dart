// lib/services/notification_service.dart
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _currentUserUUID;
  static String? _authToken;
  
  static Future<void> initialize(String userUUID, {String? authToken}) async {
    _currentUserUUID = userUUID;
    _authToken = authToken;
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions');
      
      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_sendTokenToServer);
      
      // Setup message handlers
      _setupMessageHandlers();
    } else {
      print('User denied notification permissions');
    }
  }
  
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.payload != null) {
          _handleNotificationTap(response.payload!);
        }
      },
    );
    
    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_channel',
      'Chat Messages',
      description: 'Notifications for chat messages',
      importance: Importance.high,
      // priority: Priority.high,
    );
    
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });
    
    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.messageId}');
      _handleNotificationTap(jsonEncode(message.data));
    });
  }
  
  static Future<void> _sendTokenToServer(String token) async {
    if (_currentUserUUID == null) {
      print('Cannot send FCM token: User UUID not set');
      return;
    }
    
    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? 'https://chatterg-go-production.up.railway.app';
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/users/$_currentUserUUID/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          if (_authToken != null) 'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );
      
      if (response.statusCode == 200) {
        print('FCM token updated successfully');
      } else {
        print('Failed to update FCM token: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending FCM token: $e');
    }
  }
  
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    String title = message.notification?.title ?? 'New Message';
    String body = message.notification?.body ?? 'You have a new message';
    
    // Create payload for notification tap handling
    String payload = jsonEncode(message.data);
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  static void _handleNotificationTap(String payload) {
    try {
      final data = jsonDecode(payload);
      String? senderId = data['sender_id'];
      
      if (senderId != null) {
        // TODO: Navigate to chat screen with senderId
        print('Navigate to chat with sender: $senderId');
        // You can use your navigation service here
        // NavigationService.navigateToChatScreen(senderId);
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }
  
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
  
  static Future<void> clearNotification(int notificationId) async {
    await _localNotifications.cancel(notificationId);
  }
}