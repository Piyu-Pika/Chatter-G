// lib/data/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
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
      print('Blocking send - currently processing incoming message');
      return true;
    }
    
    final now = DateTime.now();
    if (_lastSendTime != null && now.difference(_lastSendTime!) < _sendThrottleDelay) {
      print('Throttling send - too frequent');
      return true;
    }
    _lastSendTime = now;
    return false;
  }

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

  // Handle incoming messages without relying on 'type'
  void _handleMessage(dynamic data) {
    // Set flag to prevent automatic sends during message processing
    _isProcessingMessage = true;
    
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

        // Handle server ping/pong responses
        if (jsonData.containsKey('type')) {
          final messageType = jsonData['type'];
          
          if (messageType == 'ping') {
            print('Received ping from server, sending pong');
            _sendPong();
            return; // Don't process ping as a regular message
          }
          
          if (messageType == 'pong') {
            print('Received pong from server');
            return; // Don't process pong as a regular message
          }
        }

        // Add to messages stream for provider to handle
        _messagesController.add(jsonData);

        // Try to parse as ChatMessage if possible
        try {
          final message = ChatMessage.fromJson(jsonData);
          _messageController.add(message);
          print('Chat message processed: ${message.content}');
        } catch (e) {
          print('Received non-chat message or failed to parse as ChatMessage: $e');
        }
      }
    } catch (e) {
      print('Error processing WebSocket message: $e');
    } finally {
      // Reset flag after processing
      _isProcessingMessage = false;
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
      if (messageData.containsKey('content') || messageData.containsKey('recipient_id')) {
        // This looks like a chat message, validate required fields
        if (!messageData.containsKey('sender_id') || messageData['sender_id'] == null || messageData['sender_id'].toString().trim().isEmpty) {
          print('Invalid message: missing or empty sender_id');
          return;
        }
        
        if (!messageData.containsKey('recipient_id') || messageData['recipient_id'] == null || messageData['recipient_id'].toString().trim().isEmpty) {
          print('Invalid message: missing or empty recipient_id');
          return;
        }
        
        if (!messageData.containsKey('content') || messageData['content'] == null || messageData['content'].toString().trim().isEmpty) {
          print('Invalid message: missing or empty content');
          return;
        }
      }
      
      // Fix timestamp format if present
      if (messageData.containsKey('timestamp')) {
        messageData['timestamp'] = _generateTimestamp();
      }
      
      final correctedJson = jsonEncode(messageData);
      print('Sending validated message: $correctedJson');
      _channel!.sink.add(correctedJson);
      objectBox.saveMessage(messageData);
      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
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
      print('Message send throttled - too frequent');
      return;
    }

    // Validate input parameters
    if (receiverId.trim().isEmpty) {
      print('Error: receiverId is empty');
      throw Exception('Receiver ID cannot be empty');
    }

    if (message.trim().isEmpty) {
      print('Error: message content is empty');
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
      print('Sending chat message: $jsonString');

      _channel!.sink.add(jsonString);
      print('Chat message sent successfully');
    } catch (e) {
      print('Error sending chat message: $e');
      throw Exception('Failed to send chat message: $e');
    }
  }

  // Send typing indicator with validation
  Future<void> sendTypingIndicator(String receiverId, bool isTyping) async {
    if (!_isConnected || _channel == null || _currentUserId == null) {
      print('Cannot send typing indicator: not connected or user ID not set');
      return;
    }

    if (receiverId.trim().isEmpty) {
      print('Cannot send typing indicator: receiverId is empty');
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
      print('Sending typing indicator: $jsonString');
      _channel!.sink.add(jsonString);
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }

  // Mark message as read with validation
  Future<void> markAsRead(String messageId, String senderId) async {
    if (!_isConnected || _channel == null || _currentUserId == null) {
      print('Cannot mark as read: not connected or user ID not set');
      return;
    }

    if (messageId.trim().isEmpty) {
      print('Cannot mark as read: messageId is empty');
      return;
    }

    if (senderId.trim().isEmpty) {
      print('Cannot mark as read: senderId is empty');
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
      print('Sending read receipt: $jsonString');
      _channel!.sink.add(jsonString);
    } catch (e) {
      print('Error marking message as read: $e');
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
          print('Sending heartbeat ping: $pingJson');
          _channel!.sink.add(pingJson);
          print('Heartbeat ping sent successfully');
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
        final pongMessage = {
          'type': 'pong',
          'timestamp': _generateTimestamp(),
        };
        
        final pongJson = jsonEncode(pongMessage);
        print('Sending pong response: $pongJson');
        _channel!.sink.add(pongJson);
        print('Pong response sent successfully');
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
        final url =
            'wss://chatterg-go-production.up.railway.app/ws?userID=$_currentUserId';
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
