import '../../presentation/widgets/message_box.dart';

class ChatMessage {
  final String senderId;
  final String recipientId;
  // final int recipientId;
  final String content;
  final String timestamp;

  bool isRead;

  ChatMessage({
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderId: json['sender_id'],
      recipientId: json['recipient_id'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']).toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      'timestamp': timestamp.toString(),
    };
  }

  // Add the fromMessagebox factory method
  factory ChatMessage.fromMessagebox(Messagebox messagebox) {
    return ChatMessage(
      senderId: messagebox.senderId,
      recipientId: messagebox.recipientId,
      content: messagebox.text,
      timestamp: messagebox.timestamp.toString(),
    );
  }
}
