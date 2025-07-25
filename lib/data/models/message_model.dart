import '../../presentation/widgets/message_box.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class ChatMessage {
  int id = 0; // ObjectBox requires a primary key
  final String senderId;
  final String recipientId;
  final String content;
  // final String type; // "message" or "image"
  final String timestamp;

  bool isRead;

  ChatMessage({
    this.id = 0,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    // this.type = 'message',
    this.isRead = false,
  });

  // FIXED: Handle both field name formats for compatibility
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      recipientId: json['recipient_id'] ?? json['recipientId'] ?? '',
      content: json['content'] ?? '',
      // type: json['type'] ?? 'message',
      timestamp: json['timestamp'] is String
          ? json['timestamp']
          : DateTime.parse(json['timestamp']).toIso8601String(),
    );
  }

  // FIXED: Use server-compatible field names
  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      // 'type': type,
      'timestamp': timestamp,
    };
  }

  // FIXED: Use server-compatible field names for sending
  Map<String, dynamic> toServerJson() {
    return {
      'sender_id': senderId, // Changed from 'senderId'
      'recipient_id': recipientId, // Changed from 'recipientId'
      'content': content,
      // 'timestamp': timestamp,
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
