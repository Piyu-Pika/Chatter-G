// lib/data/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

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

  // Connect to WebSocket server
  Future<void> connect(String url) async {
    // Extract userId from URL
    final uri = Uri.parse(url);
    final userId = uri.queryParameters['userID'];
    
    if (_isConnected && _currentUserId == userId) {
      print('Already connected for user: $userId');
      return;
    }

    try {
      _currentUserId = userId;
      print('Connecting to WebSocket: $url');
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

      print('WebSocket connected successfully for user: $userId');
    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnected = false;
      _connectionController.add('error: $e');
      _scheduleReconnect();
      rethrow;
    }
  }

  // Fixed: Handle incoming messages
  void _handleMessage(dynamic data) {
    try {
      print('Raw WebSocket message received: $data');

      if (data is String) {
        final jsonData = jsonDecode(data);
        print('Parsed JSON: $jsonData');

        // Check for error messages from server
        if (jsonData.containsKey('error')) {
          print('Server error: ${jsonData['error']}');
          return;
        }

        // Add to messages stream for provider to handle
        _messagesController.add(jsonData);

        // Handle different message types
        if (jsonData['type'] == 'message') {
          final message = ChatMessage.fromJson(jsonData);
          _messageController.add(message);
          print('Chat message processed: ${message.content}');
        } else if (jsonData['type'] == 'ping') {
          // Respond to ping with pong
          _sendPong();
        } else {
          print('Unknown message type: ${jsonData['type']}');
        }
      }
    } catch (e) {
      print('Error processing WebSocket message: $e');
    }
  }

  // Handle WebSocket errors
  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    _connectionController.add('error: $error');
    _scheduleReconnect();
  }

  // Handle WebSocket disconnection
  void _handleDisconnection() {
    print('WebSocket disconnected');
    _isConnected = false;
    _connectionController.add('disconnected');
    _stopHeartbeat();
    _scheduleReconnect();
  }

  // FIXED: Simplified and corrected sendMessage method
  Future<void> sendMessage(String messageJson, String roomName) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    if (_currentUserId == null) {
      throw Exception('User ID not set');
    }

    try {
      // Simply send the JSON string as-is since it should already be properly formatted
      print('Sending message: $messageJson');
      _channel!.sink.add(messageJson);
      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // FIXED: Corrected sendChatMessage method with proper field names
  Future<void> sendChatMessage(String receiverId, String message) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    if (_currentUserId == null) {
      throw Exception('User ID not set');
    }

    try {
      // Use the correct field names that match the server model
      final messageData = {
        'type': 'message',
        'sender_id': _currentUserId!, // Changed from 'senderId' to 'sender_id'
        'recipient_id': receiverId,   // Changed from 'recipientId' to 'recipient_id'
        'content': message,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(messageData);
      print('Sending message: $jsonString');

      _channel!.sink.add(jsonString);
      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Send typing indicator
  Future<void> sendTypingIndicator(String receiverId, bool isTyping) async {
    if (!_isConnected || _channel == null || _currentUserId == null) return;

    try {
      final typingData = {
        'type': 'typing',
        'sender_id': _currentUserId,
        'receiver_id': receiverId,
        'is_typing': isTyping,
      };

      _channel!.sink.add(jsonEncode(typingData));
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }

  // Mark message as read
  Future<void> markAsRead(String messageId, String senderId) async {
    if (!_isConnected || _channel == null || _currentUserId == null) return;

    try {
      final readData = {
        'type': 'read',
        'message_id': messageId,
        'sender_id': senderId,
        'reader_id': _currentUserId,
      };

      _channel!.sink.add(jsonEncode(readData));
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  // Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          print('Error sending heartbeat: $e');
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
        _channel!.sink.add(jsonEncode({'type': 'pong'}));
      } catch (e) {
        print('Error sending pong: $e');
      }
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnection attempts reached');
      _connectionController.add('max_reconnect_attempts_reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_currentUserId != null && !_isConnected) {
        _reconnectAttempts++;
        print('Reconnection attempt $_reconnectAttempts');
        final url = 'wss://chatterg-go-production.up.railway.app/ws?userID=$_currentUserId';
        connect(url).catchError((e) {
          print('Reconnection failed: $e');
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

      print('WebSocket disconnected successfully');
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
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