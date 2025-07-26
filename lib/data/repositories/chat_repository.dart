import '../models/message_model.dart';

abstract class ChatRepository {
  Stream<ChatMessage> get messageStream;
  Stream<String> get connectionStream;
  bool get isConnected;
  String? get currentUserId;

  Future<void> connect(String userId);
  Future<void> disconnect();
  Future<void> sendMessage(String receiverId, String message, String senderId);
  Future<void> markAsRead(String messageId, String senderId);
  Future<void> sendTypingIndicator(String receiverId, bool isTyping);
  Future<List<ChatMessage>> getChatHistory(String userId1, String userId2);
  void dispose();
}
