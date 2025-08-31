import '../../presentation/widgets/message_box.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
class ChatMessage {
  int id = 0;
  final String senderId;
  final String recipientId;
  final String content;
  final String timestamp;
  final String? messageType;
  final String? fileType;
  bool isRead;

  ChatMessage({
    this.id = 0,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.messageType,
    this.fileType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      senderId: json['sender_id']?.toString() ?? '',
      recipientId: json['recipient_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      isRead: json['is_read'] == true,
      messageType: json['message_type']?.toString(),
      fileType: json['file_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      'timestamp': timestamp,
      'is_read': isRead,
      if (messageType != null) 'message_type': messageType,
      if (fileType != null) 'file_type': fileType,
    };
  }

  // Helper method to check if message is an image
  bool get isImage => messageType == 'image';
  
  // Check if this is an image notification (content is image ID)
  bool get isImageNotification => messageType == 'image' && content.length <= 50;

  Map<String, dynamic> toServerJson() {
    return {
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
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
