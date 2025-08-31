// lib/data/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:chatterg/data/datasources/remote/api_value.dart';
import 'package:dev_log/dev_log.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import '../../../main.dart';
import '../../models/message_model.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<String> _connectionController =
      StreamController<String>.broadcast();

  bool _isConnected = false;
  String? _currentUserId;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Add throttling to prevent rapid sends
  DateTime? _lastSendTime;
  static const Duration _sendThrottleDelay = Duration(milliseconds: 100);

  // Add flag to prevent automatic sends during message processing
  bool _isProcessingMessage = false;

  // Getters
  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<String> get connectionStream => _connectionController.stream;

  // Fixed: StreamController to handle incoming messages as JSON
  final StreamController<Map<String, dynamic>> _messagesController =
      StreamController.broadcast();

  // Expose the messages stream
  Stream<Map<String, dynamic>> get messages => _messagesController.stream;

  // Helper method to generate proper RFC3339 timestamp
  String _generateTimestamp() {
    return DateTime.now().toUtc().toIso8601String();
  }

  // Helper method to check if we should throttle sends
  bool _shouldThrottleSend() {
    // Don't send during message processing to prevent automatic sends
    if (_isProcessingMessage) {
      L.i('Blocking send - currently processing incoming message');
      return true;
    }

    final now = DateTime.now();
    if (_lastSendTime != null &&
        now.difference(_lastSendTime!) < _sendThrottleDelay) {
      L.i('Throttling send - too frequent');
      return true;
    }
    _lastSendTime = now;
    return false;
  }

  void reconnect() {
    if (_currentUserId != null) {
      final url =
          // 'wss://chatterg-go-production.up.railway.app/ws?userID=$_currentUserId';
          // 'wss://abfcbf7ad979.ngrok-free.app/ws?userID=$_currentUserId';
          '${dotenv.env['WEBSOCKET_URL']}/ws?userID=$_currentUserId';
          
      connect(url);
    }
  }

  // Connect to WebSocket server
  Future<void> connect(String url) async {
    // Extract userId from URL
    final uri = Uri.parse(url);
    final userId = uri.queryParameters['userID'];

    if (_isConnected && _currentUserId == userId) {
      L.i('Already connected for user: $userId');
      return;
    }

    try {
      _currentUserId = userId;
      L.i('Connecting to WebSocket: $url');
      _channel = IOWebSocketChannel.connect(uri);

      // Listen to the stream
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add('connected');
      _startHeartbeat();

      L.i('WebSocket connected successfully for user: $userId');
    } catch (e) {
      L.e('WebSocket connection error: $e');
      _isConnected = false;
      _connectionController.add('error: $e');
      _scheduleReconnect();
      rethrow;
    }
  }

  // Handle incoming messages without relying on 'type'
  // Updated _handleMessage method in websocket_data_source.dart
void _handleMessage(dynamic data) {
  _isProcessingMessage = true;
  try {
    L.json('Raw WebSocket message received: $data');
    if (data is String) {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      L.json('Parsed JSON: $jsonData');
      
      // Handle server responses
      if (jsonData.containsKey('error')) {
        L.e('Server error: ${jsonData['error']}');
        return;
      }

      // Handle ping/pong
      if (jsonData.containsKey('type')) {
        final messageType = jsonData['type'];
        if (messageType == 'ping') {
          L.i('Received ping from server, sending pong');
          _sendPong();
          return;
        }

        if (messageType == 'pong') {
          L.i('Received pong from server');
          return;
        }
      }

      // Check if this is an image notification
      if (jsonData['message_type'] == 'image_notification') {
        L.i('Processing image notification: ${jsonData['id']}');
        
        // Convert notification to ChatMessage format
        final notificationMessage = ChatMessage(
          senderId: jsonData['sender_id']?.toString() ?? '',
          recipientId: jsonData['recipient_id']?.toString() ?? '',
          content: jsonData['id']?.toString() ?? '', // Store image ID as content
          timestamp: jsonData['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
          messageType: 'image',
          fileType: jsonData['file_type']?.toString() ?? '',
          isRead: false,
        );
        
        L.i('Created image notification message: ${notificationMessage.toJson()}');
        
        // Add to message stream
        _messageController.add(notificationMessage);
        
        // Also add to the messages stream for the provider
        _messagesController.add(notificationMessage.toJson());
        
        return;
      }

      // Add to messages stream for provider to handle
      _messagesController.add(jsonData);
      
      // Try to parse as regular ChatMessage
      try {
        final message = ChatMessage.fromJson(jsonData);
        _messageController.add(message);
        L.i('Message processed - Type: ${message.messageType ?? 'text'}, Content length: ${message.content.length}');
      } catch (e) {
        L.e('Failed to parse as ChatMessage: $e');
      }
    }
  } catch (e) {
    L.e('Error processing WebSocket message: $e');
  } finally {
    _isProcessingMessage = false;
  }
}

  // Handle WebSocket errors
  void _handleError(dynamic error) {
    L.e('WebSocket error: $error');
    _isConnected = false;
    _connectionController.add('error: $error');
    _scheduleReconnect();
  }

  // Handle WebSocket disconnection
  void _handleDisconnection() {
    L.i('WebSocket disconnected');
    _isConnected = false;
    _connectionController.add('disconnected');
    _stopHeartbeat();
    _scheduleReconnect();
  }

  // FIXED: Simplified and corrected sendMessage method with validation
  Future<void> sendMessage(String messageJson, String roomName) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    if (_currentUserId == null) {
      throw Exception('User ID not set');
    }

    try {
      // Parse the JSON to validate and fix it
      final messageData = jsonDecode(messageJson);

      // Validate required fields for chat messages
      if (messageData.containsKey('content') ||
          messageData.containsKey('recipient_id')) {
        // This looks like a chat message, validate required fields
        if (!messageData.containsKey('sender_id') ||
            messageData['sender_id'] == null ||
            messageData['sender_id'].toString().trim().isEmpty) {
          L.wtf('Invalid message: missing or empty sender_id');
          return;
        }

        if (!messageData.containsKey('recipient_id') ||
            messageData['recipient_id'] == null ||
            messageData['recipient_id'].toString().trim().isEmpty) {
          L.wtf('Invalid message: missing or empty recipient_id');
          return;
        }

        if (!messageData.containsKey('content') ||
            messageData['content'] == null ||
            messageData['content'].toString().trim().isEmpty) {
          L.wtf('Invalid message: missing or empty content');
          return;
        }
      }

      // Fix timestamp format if present
      if (messageData.containsKey('timestamp')) {
        messageData['timestamp'] = _generateTimestamp();
      }

      final correctedJson = jsonEncode(messageData);
      L.i('Sending validated message: $correctedJson');
      _channel!.sink.add(correctedJson);
      objectBox.saveMessage(messageData);
      L.i('Message sent successfully');
    } catch (e) {
      L.e('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // FIXED: Corrected sendChatMessage method with proper validation
  Future<void> sendChatMessage(String receiverId, String message) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    if (_currentUserId == null) {
      throw Exception('User ID not set');
    }

    // Throttle rapid sends
    if (_shouldThrottleSend()) {
      L.i('Message send throttled - too frequent');
      return;
    }

    // Validate input parameters
    if (receiverId.trim().isEmpty) {
      L.e('Error: receiverId is empty');
      throw Exception('Receiver ID cannot be empty');
    }

    if (message.trim().isEmpty) {
      L.e('Error: message content is empty');
      throw Exception('Message content cannot be empty');
    }

    try {
      // Use the correct field names that match the server model
      final messageData = {
        'sender_id': _currentUserId!,
        'recipient_id': receiverId.trim(),
        'content': message.trim(),
        'timestamp': _generateTimestamp(), // Fixed: Use proper UTC timestamp
      };

      final jsonString = jsonEncode(messageData);
      L.json('Sending chat message: $jsonString');

      _channel!.sink.add(jsonString);
      L.i('Chat message sent successfully');
    } catch (e) {
      L.e('Error sending chat message: $e');
      throw Exception('Failed to send chat message: $e');
    }
  }

  // Send typing indicator with validation
  Future<void> sendTypingIndicator(String receiverId, bool isTyping) async {
    if (!_isConnected || _channel == null || _currentUserId == null) {
      L.e('Cannot send typing indicator: not connected or user ID not set');
      return;
    }

    if (receiverId.trim().isEmpty) {
      L.e('Cannot send typing indicator: receiverId is empty');
      return;
    }

    try {
      final typingData = {
        'type': 'typing', // Add type for typing indicators
        'sender_id': _currentUserId,
        'receiver_id': receiverId.trim(),
        'is_typing': isTyping,
        'timestamp': _generateTimestamp(),
      };

      final jsonString = jsonEncode(typingData);
      L.i('Sending typing indicator: $jsonString');
      _channel!.sink.add(jsonString);
    } catch (e) {
      L.e('Error sending typing indicator: $e');
    }
  }

  // Mark message as read with validation
  Future<void> markAsRead(String messageId, String senderId) async {
    if (!_isConnected || _channel == null || _currentUserId == null) {
      L.e('Cannot mark as read: not connected or user ID not set');
      return;
    }

    if (messageId.trim().isEmpty) {
      L.e('Cannot mark as read: messageId is empty');
      return;
    }

    if (senderId.trim().isEmpty) {
      L.e('Cannot mark as read: senderId is empty');
      return;
    }

    try {
      final readData = {
        'type': 'read', // Add type for read receipts
        'message_id': messageId.trim(),
        'sender_id': senderId.trim(),
        'reader_id': _currentUserId,
        'timestamp': _generateTimestamp(),
      };

      final jsonString = jsonEncode(readData);
      L.i('Sending read receipt: $jsonString');
      _channel!.sink.add(jsonString);
    } catch (e) {
      L.e('Error marking message as read: $e');
    }
  }

  // Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          // Send ONLY the ping message, don't trigger any other sends
          final pingMessage = {
            'type': 'ping',
            'timestamp': _generateTimestamp(),
          };

          final pingJson = jsonEncode(pingMessage);
          L.json('Sending heartbeat ping: $pingJson');
          _channel!.sink.add(pingJson);
          L.i('Heartbeat ping sent successfully');
        } catch (e) {
          L.e('Error sending heartbeat: $e');
        }
      } else {
        timer.cancel();
      }
    });
  }

  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Send pong response
  void _sendPong() {
    if (_isConnected && _channel != null) {
      try {
        final pongMessage = {
          'type': 'pong',
          'timestamp': _generateTimestamp(),
        };

        final pongJson = jsonEncode(pongMessage);
        L.json('Sending pong response: $pongJson');
        _channel!.sink.add(pongJson);
        L.i('Pong response sent successfully');
      } catch (e) {
        L.e('Error sending pong: $e');
      }
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      L.i('Max reconnection attempts reached');
      _connectionController.add('max_reconnect_attempts_reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_currentUserId != null && !_isConnected) {
        _reconnectAttempts++;
        L.i('Reconnection attempt $_reconnectAttempts');
        final url =
            // 'wss://chatterg-go-production.up.railway.app/ws?userID=$_currentUserId';
            // 'wss://abfcbf7ad979.ngrok-free.app/ws?userID=$_currentUserId';
            '${dotenv.env['WEBSOCKET_URL']}/ws?userID=$_currentUserId';
        connect(url).catchError((e) {
          L.wtf('Reconnection failed: $e');
        });
      }
    });
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    try {
      _stopHeartbeat();
      _reconnectTimer?.cancel();

      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }

      _isConnected = false;
      _currentUserId = null;
      _reconnectAttempts = 0;
      _connectionController.add('disconnected');

      L.i('WebSocket disconnected successfully');
    } catch (e) {
      L.e('Error disconnecting WebSocket: $e');
    }
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
    _stopHeartbeat();
    _messagesController.close();
    _reconnectTimer?.cancel();
  }
}
