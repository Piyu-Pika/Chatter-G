import '../../presentation/widgets/message_box.dart';

class ChatMessage {
  final String senderId;
  final String recipientId;
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

  // FIXED: Handle both field name formats for compatibility
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderId: json['sender_id'] ?? json['senderId'] ?? '',
      recipientId: json['recipient_id'] ?? json['recipientId'] ?? '',
      content: json['content'] ?? '',
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
      'timestamp': timestamp,
    };
  }

  // FIXED: Use server-compatible field names for sending
  Map<String, dynamic> toServerJson() {
    return {
      'type': 'message',
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      'timestamp': timestamp,
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