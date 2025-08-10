import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/websocket_data_source.dart';
import '../../data/models/message_model.dart';
import '../../main.dart';
import 'auth_provider.dart';

// WebSocket Service Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final webSocketConnectionProvider = FutureProvider<void>((ref) async {
  final authService = ref.read(authServiceProvider);
  final userId = authService.currentUser?.uid;
  if (userId == null) {
    throw Exception('User not authenticated');
  }
  
  // final url = 'wss://chatterg-go-production.up.railway.app/ws?userID=$userId';
  // final url = 'wss://abfcbf7ad979.ngrok-free.app/ws?userID=$userId';
  final url = '${dotenv.env['WEBSOCKET_URL']}/ws?userID=$userId';
  await ref.read(webSocketServiceProvider).connect(url);
});

// Chat Messages Notifier
class ChatMessagesNotifier
    extends StateNotifier<Map<String, List<ChatMessage>>> {
  final Ref ref;

  ChatMessagesNotifier(this.ref) : super({}) {
    _initializeWebSocketListener();
  }

  void _initializeWebSocketListener() {
    final webSocketService = ref.read(webSocketServiceProvider);

    webSocketService.messages.listen((data) {
      try {
        print('Received message data: $data');

        // Try to parse as ChatMessage without relying on 'type'
        final message = ChatMessage.fromJson(data);
        addMessage(message);
      } catch (e) {
        print('Non-chat or invalid message format: $e');
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    });
  }

  void addMessage(ChatMessage message) {
    final roomName = getRoomName(message.senderId, message.recipientId);
    print('Adding message to room: $roomName');

    // Save message to ObjectBox (local database)
    objectBox.saveMessage(message);

    // Get current messages for the room
    final currentMessages = state[roomName] ?? [];

    // Check if message already exists to avoid duplicates
    final messageExists = currentMessages.any((m) =>
        m.timestamp == message.timestamp &&
        m.senderId == message.senderId &&
        m.content == message.content);

    if (!messageExists) {
      final updatedMessages = [...currentMessages, message];

      // Sort messages by timestamp
      updatedMessages.sort((a, b) {
        try {
          final aTime = DateTime.parse(a.timestamp);
          final bTime = DateTime.parse(b.timestamp);
          return aTime.compareTo(bTime);
        } catch (e) {
          print('Error parsing timestamp for sorting: $e');
          return 0;
        }
      });

      state = {
        ...state,
        roomName: updatedMessages,
      };

      print(
          'Message added to room $roomName. Total messages: ${updatedMessages.length}');
    } else {
      print('Message already exists, skipping duplicate');
    }
  }

  // void _markMessageAsRead(String messageId, String senderId) {
  //   // Find the room containing this message
  //   for (final roomName in state.keys) {
  //     final messages = state[roomName] ?? [];
  //     final updatedMessages = messages.map((message) {
  //       if (message.timestamp == messageId && message.senderId == senderId) {
  //         return ChatMessage(
  //           senderId: message.senderId,
  //           recipientId: message.recipientId,
  //           content: message.content,
  //           timestamp: message.timestamp,
  //           isRead: true,
  //         );
  //       }
  //       return message;
  //     }).toList();

  //     if (updatedMessages != messages) {
  //       state = {
  //         ...state,
  //         roomName: updatedMessages,
  //       };
  //       break;
  //     }
  //   }
  // }

  // Method to get messages for a specific room
  List<ChatMessage> getMessagesForRoom(String roomName) {
    return state[roomName] ?? [];
  }

  // Method to clear messages for a room
  void clearMessagesForRoom(String roomName) {
    state = {
      ...state,
      roomName: [],
    };
  }

  // Method to load historical messages (if you have an API for this)
  Future<void> loadHistoricalMessages(
      String roomName, String userId1, String userId2) async {
    // Implement API call to load historical messages
    // This would typically be called when entering a chat room
    print('Loading historical messages for room: $roomName');
    // Example:
    // final historicalMessages = await chatRepository.getMessages(userId1, userId2);
    // for (final message in historicalMessages) {
    //   addMessage(message);
    // }
  }
}

final chatMessagesProvider =
    StateNotifierProvider<ChatMessagesNotifier, Map<String, List<ChatMessage>>>(
        (ref) => ChatMessagesNotifier(ref));

// Helper function to get room name
String getRoomName(String user1, String user2) {
  final users = [user1, user2]..sort();
  return users.join('_');
}
