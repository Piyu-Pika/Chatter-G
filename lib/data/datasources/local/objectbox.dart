import '../../../objectbox.g.dart';
import '../../models/message_model.dart';


class ObjectBox {
  late final Store store;
  late final Box<ChatMessage> chatBox;

  ObjectBox._create(this.store) {
    chatBox = Box<ChatMessage>(store);
  }

  static Future<ObjectBox> create() async {
    final store = await openStore();
    return ObjectBox._create(store);
  }

  void saveMessage(ChatMessage message) {
    chatBox.put(message);
  }

  List<ChatMessage> getMessagesFor(String userId1, String userId2) {
    final query = chatBox.query(
  ChatMessage_.senderId.equals(userId1).and(ChatMessage_.recipientId.equals(userId2))
    |
  ChatMessage_.senderId.equals(userId2).and(ChatMessage_.recipientId.equals(userId1))
).build();


    final messages = query.find();
    query.close();
    return messages;
  }

  void deleteAllMessages() {
    chatBox.removeAll();
  }

  void deleteMessageById(int id) {
    chatBox.remove(id);
  }
}
