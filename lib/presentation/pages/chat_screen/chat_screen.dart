import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/message_model.dart';
import 'chat_provider.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatScreenProvider);
    final chatNotifier = ref.read(chatScreenProvider.notifier);
    final messages = chatState.messages;
    
    print('Rendering ${messages.length} messages');
    
    // Sort messages by timestamp
    final sortedMessages = List<ChatMessage>.from(messages);
    sortedMessages.sort((a, b) {
      try {
        final aTime = DateTime.parse(a.timestamp);
        final bTime = DateTime.parse(b.timestamp);
        return aTime.compareTo(bTime);
      } catch (e) {
        print('Error parsing timestamp for sorting: $e');
        return 0;
      }
    });
    
    final groupedMessages = chatNotifier.groupMessagesByDate(sortedMessages);
    print('Grouped messages: ${groupedMessages.keys}');

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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dateKeys = groupedMessages.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatState.receiver.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  chatState.receiver.isOnline == true ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: chatState.receiver.isOnline == true
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ],
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
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Say hello to ${chatState.receiver.name}!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.withOpacity(0.6),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
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
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            ),
                            ...dateMessages.map((message) {
                              final isUser =
                                  message.senderId == chatState.currentUserUuid;
                              if (!isUser && !message.isRead) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  chatNotifier.markAsRead(message);
                                });
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: isUser
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isUser)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: CircleAvatar(
                                          child: Text(chatState.receiver.name[0]
                                              .toUpperCase()),
                                        ),
                                      ),
                                    Flexible(
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.7,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 10.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isUser
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.content,
                                              style: TextStyle(
                                                color: isUser
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('HH:mm')
                                                  .format(DateTime.parse(message.timestamp)),
                                              style: TextStyle(
                                                color: isUser
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary
                                                        .withOpacity(0.7)
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.6),
                                                fontSize: 10,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isUser)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8.0),
                                        child: Icon(
                                          message.isRead
                                              ? Icons.done_all
                                              : Icons.done,
                                          size: 16,
                                          color: message.isRead
                                              ? Colors.blue
                                              : Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      // Implement attachment function
                    },
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
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
                                contentPadding:
                                    EdgeInsets.symmetric(vertical: 12),
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
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
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
}
