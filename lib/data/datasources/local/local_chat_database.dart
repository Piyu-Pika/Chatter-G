// filepath: d:/ChatterG/lib/data/datasources/local/local_chat_database.dart
import 'package:hive/hive.dart';
import '../../models/message_model.dart';

class LocalChatDatabase {
  static const String _chatBoxName = 'chatBox';

  // Initialize Hive
  Future<void> init() async {
    Hive.registerAdapter(ChatMessageAdapter());
    await Hive.openBox<ChatMessage>(_chatBoxName);
  }

  // Save a chat message
  Future<void> saveMessage(ChatMessage message) async {
    final box = Hive.box<ChatMessage>(_chatBoxName);
    await box.add(message);
  }

  // Retrieve all messages
  List<ChatMessage> getMessages() {
    final box = Hive.box<ChatMessage>(_chatBoxName);
    return box.values.toList();
  }

  // Delete a specific message
  Future<void> deleteMessage(int index) async {
    final box = Hive.box<ChatMessage>(_chatBoxName);
    await box.deleteAt(index);
  }

  // Clear all messages
  Future<void> clearMessages() async {
    final box = Hive.box<ChatMessage>(_chatBoxName);
    await box.clear();
  }
}

// Hive adapter for ChatMessage
class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 0;

  @override
  ChatMessage read(BinaryReader reader) {
    return ChatMessage(
      senderId: reader.readString(),
      recipientId: reader.readString(),
      content: reader.readString(),
      timestamp: reader.readInt().toString(),
      isRead: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer.writeString(obj.senderId);
    writer.writeString(obj.recipientId);
    writer.writeString(obj.content);
    writer.writeInt(obj.timestamp.isNotEmpty
        ? int.parse(obj.timestamp)
        : DateTime.now().millisecondsSinceEpoch);
    writer.writeBool(obj.isRead);
  }
}
