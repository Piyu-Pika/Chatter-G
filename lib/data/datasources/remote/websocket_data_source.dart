import 'package:web_socket_channel/io.dart';
import 'dart:async';
import 'dart:convert';

import '../../models/message_model.dart';

class WebSocketService {
  late IOWebSocketChannel channel;
  final StreamController<dynamic> _messagesController =
      StreamController<dynamic>.broadcast();
  bool _isConnected = false;

  // Initialize WebSocket connection
  Future<void> connect(String url) async {
    try {
      channel = IOWebSocketChannel.connect(url);
      _isConnected = true;
      print('WebSocket connected to $url');

      // Forward messages from the channel to our controller
      channel.stream.listen((message) {
        _messagesController.add(jsonDecode(message));
      }, onError: (error) {
        _isConnected = false;
        _messagesController.addError(error);
      }, onDone: () {
        _isConnected = false;
        disconnect();
      });
    } catch (e) {
      _isConnected = false;
      print('WebSocket connection error: $e');
      throw e;
    }
  }

  // Listen for messages from the WebSocket server
  Stream<Map<String, ChatMessage>> get messages =>
      channel.stream.map((message) => jsonDecode(message)).map((message) {
        final chatMessage = ChatMessage.fromJson(message);
        return {chatMessage.recipientId: chatMessage};
      });

  // Send message to the WebSocket server
  void sendMessage(Map<String, dynamic> message) {
    if (!_isConnected) {
      throw Exception('WebSocket not connected');
    }
    channel.sink.add(message);
  }

  // Close the connection
  void disconnect() {
    channel.sink.close();
    _isConnected = false;
  }

  // Check if connected
  bool get isConnected => _isConnected;

  // Dispose resources
  void dispose() {
    disconnect();
    _messagesController.close();
  }
}
