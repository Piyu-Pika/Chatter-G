import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/websocket_data_source.dart';
import '../../data/models/message_model.dart';
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
  final url = 'ws://chatterg.leapcell.app/ws?userID=$userId';
  await ref.read(webSocketServiceProvider).connect(url);
});

// Chat Messages Notifier
class ChatMessagesNotifier
    extends StateNotifier<Map<String, List<ChatMessage>>> {
  ChatMessagesNotifier(this.ref) : super({}) {
    final webSocketService = ref.watch(webSocketServiceProvider);
    webSocketService.messages.listen((data) {
      final message = ChatMessage.fromJson(data);
      addMessage(message);
    }, onError: (error) {
      print('WebSocket error: $error');
    });
  }

  final Ref ref;

  void addMessage(ChatMessage message) {
    final roomName = getRoomName(message.senderId, message.recipientId);
    state = {
      ...state,
      roomName: [...state[roomName] ?? [], message],
    };
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
