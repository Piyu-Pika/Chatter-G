import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../data/datasources/remote/navigation_service.dart';
import '../../../data/datasources/remote/notification_service.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../util/image_encoding.dart';
import '../../reciver_profile/reciver_profile.dart';
import '../../widgets/message_box.dart';
import '../../providers/websocket_provider.dart';
import '../camera_screen/camera_screen.dart';
import 'chat_provider.dart';
import 'package:dev_log/dev_log.dart';


class ChatScreen extends ConsumerWidget {
  final AppUser receiver;

  const ChatScreen({super.key, required this.receiver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatScreenProvider(receiver.uuid));
    final chatNotifier = ref.read(chatScreenProvider(receiver.uuid).notifier);
    final messages = chatState.messages;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationService.setCurrentChatUser(receiver.uuid);
      NotificationService.clearNotificationsForUser(receiver.uuid);
    });

    L.i('Rendering ${messages.length} messages for ${receiver.name}');

    if (!chatState.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(receiver.name)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (chatState.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chat Error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  chatState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sortedMessages = List<ChatMessage>.from(messages);
    sortedMessages.sort((a, b) {
      try {
        final aTime = DateTime.parse(a.timestamp);
        final bTime = DateTime.parse(b.timestamp);
        return aTime.compareTo(bTime);
      } catch (e) {
        L.e('Error parsing timestamp for sorting: $e');
        return 0;
      }
    });

    final groupedMessages = chatNotifier.groupMessagesByDate(sortedMessages);
    final dateKeys = groupedMessages.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReciverProfileScreen(uuid: receiver.uuid),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receiver.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    receiver.isOnline == true ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: receiver.isOnline == true ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () {
              // Implement video call function
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Implement voice call function
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF1E1E1E),
              ),
              child: sortedMessages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.withAlpha(255),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Say hello to ${receiver.name}!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.withAlpha(192),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: chatState.scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: dateKeys.length,
                      itemBuilder: (context, dateIndex) {
                        final dateKey = dateKeys[dateIndex];
                        final dateMessages = groupedMessages[dateKey]!;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    chatNotifier.getReadableDate(dateKey),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            ),
                            ...dateMessages.map((message) {
                              final isUser = message.senderId == chatState.currentUserUuid;

                              if (!isUser && !message.isRead) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  chatNotifier.markAsRead(message);
                                });
                              }

                              return Column(
                                children: [
                                  Messagebox(
                                    text: message.content,
                                    isUser: isUser,
                                    senderId: message.senderId,
                                    recipientId: message.recipientId,
                                    timestamp: DateTime.parse(message.timestamp),
                                    messageType: message.messageType,
                                    fileType: message.fileType,
                                  ),
                                  if (isUser)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 16.0,
                                        top: 4.0,
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            DateFormat('HH:mm').format(
                                              DateTime.parse(message.timestamp)
                                                  .toUtc()
                                                  .toLocal(),
                                            ),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.withAlpha(223),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            message.isRead ? Icons.done_all : Icons.done,
                                            size: 16,
                                            color: message.isRead ? Colors.blue : Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!isUser)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        top: 4.0,
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat('HH:mm').format(
                                              DateTime.parse(message.timestamp)
                                                  .toUtc()
                                                  .toLocal(),
                                            ),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.withAlpha(223),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () => _showAttachmentOptions(context, ref),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: chatState.textController,
                              decoration: const InputDecoration(
                                hintText: 'Type a message',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              maxLines: 5,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              onSubmitted: (text) {
                                if (text.trim().isNotEmpty) {
                                  chatNotifier.sendMessage(text.trim());
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined),
                            onPressed: () {
                              // Implement emoji picker
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      final text = chatState.textController.text.trim();
                      if (text.isNotEmpty) {
                        chatNotifier.sendMessage(text);
                      }
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    elevation: 2,
                    child: chatState.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Camera'),
              subtitle: const Text('Take a photo'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatCameraScreen(
                      receiverUuid: receiver.uuid,
                      receiverName: receiver.name,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromGallery(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context, WidgetRef ref) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Read image bytes
        final bytes = await File(image.path).readAsBytes();
        
        // Use optimized encoding
        final base64Image = ImageEncoding.encodeImage(bytes, quality: 85);
        final fileExtension = image.path.split('.').last.toLowerCase();

        // Send via WebSocket with optimized encoding
        final webSocketService = ref.read(webSocketServiceProvider);
        await webSocketService.sendImageMessage(
          receiver.uuid,
          base64Image,
          fileExtension,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
