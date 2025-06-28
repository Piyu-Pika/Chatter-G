import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';

class ChatScreenState {
  final String roomName;
  final String currentUserUuid;
  final User receiver;
  final TextEditingController textController;
  final ScrollController scrollController;
  final String? errorMessage;
  final bool isLoading;
  final List<ChatMessage> messages;

  ChatScreenState({
    required this.roomName,
    required this.currentUserUuid,
    required this.receiver,
    required this.textController,
    required this.scrollController,
    this.errorMessage,
    required this.isLoading,
    required this.messages,
  });

  ChatScreenState copyWith({
    String? roomName,
    String? currentUserUuid,
    User? receiver,
    TextEditingController? textController,
    ScrollController? scrollController,
    String? errorMessage,
    bool? isLoading,
    List<ChatMessage>? messages,
  }) {
    return ChatScreenState(
      roomName: roomName ?? this.roomName,
      currentUserUuid: currentUserUuid ?? this.currentUserUuid,
      receiver: receiver ?? this.receiver,
      textController: textController ?? this.textController,
      scrollController: scrollController ?? this.scrollController,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
    );
  }
}

class ChatScreenNotifier extends StateNotifier<ChatScreenState> {
  final Ref ref;

  ChatScreenNotifier(this.ref)
      : super(ChatScreenState(
          roomName: '',
          currentUserUuid: '',
          receiver: User(
            uuid: '',
            name: '',
            email: '',
            username: '',
            bio: '',
            dateOfBirth: '', // Replace with actual date
            gender: '',
            phoneNumber: '',
            createdAt: '', // Replace with actual creation date
            updatedAt: '', // Replace with actual update date
          ), // Replace with actual User initialization
          textController: TextEditingController(),
          scrollController: ScrollController(),
          isLoading: false,
          messages: [],
        )) {
    _initializeChat();
  }

  void _initializeChat() {
    try {
      print('Initializing chat...');
      final authProvider = ref.read(authServiceProvider);
      final currentUserUuid = authProvider.currentUser?.uid ?? '';
      final receiver = ref.read(currentReceiverProvider);
      if (receiver == null) {
        throw Exception('Receiver not set');
      }
      final roomName = getRoomName(currentUserUuid, receiver.uuid);
      final webSocketService = ref.read(webSocketServiceProvider);
      if (!webSocketService.isConnected) {
        print('WebSocket not connected. Attempting to connect...');
        webSocketService
            .connect('ws://chatterg-.leapcell.app/ws?userID=$currentUserUuid');
      }

      state = state.copyWith(
        currentUserUuid: currentUserUuid,
        receiver: receiver,
        roomName: roomName,
      );

      print('Chat initialized with roomName: $roomName');

      // Scroll to bottom after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Watch messages for the room
      ref.listen(chatMessagesProvider, (previous, next) {
        final messages = next[roomName] ?? [];
        print('New messages received: ${messages.length}');
        state = state.copyWith(messages: messages);
      });
    } catch (e) {
      print('Error initializing chat: $e');
      state = state.copyWith(errorMessage: 'Error initializing chat: $e');
    }
  }

  void markAsRead(ChatMessage message) {
    final updatedMessages = state.messages.map((m) {
      if (m == message) {
        return ChatMessage(
          senderId: m.senderId,
          recipientId: m.recipientId,
          content: m.content,
          timestamp: m.timestamp,
          isRead: true,
        );
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updatedMessages);
    // Optionally notify the server to mark the message as read
    final webSocketService = ref.read(webSocketServiceProvider);
    webSocketService.sendMessage({
      'type': 'read',
      'message_id': message.timestamp, // Use a unique message ID
      'recipient_id': message.senderId,
    });
  }

  void _scrollToBottom() {
    if (state.scrollController.hasClients) {
      print('Scrolling to bottom...');
      state.scrollController.animateTo(
        state.scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void sendMessage(String text) {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      final message = ChatMessage(
        senderId: state.currentUserUuid,
        recipientId: state.receiver.uuid,
        content: text,
        timestamp: DateTime.now().toString(),
      ).toJson();
      print('Sending message JSON: $message');
      final webSocketService = ref.read(webSocketServiceProvider);
      if (!webSocketService.isConnected) {
        throw Exception('WebSocket not connected');
      }
      webSocketService.sendMessage(message); // Encode to JSON string
      print('Message sent successfully');
      state.textController.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Failed to send message: $e');
      state = state.copyWith(errorMessage: 'Failed to send message: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Map<String, List<dynamic>> groupMessagesByDate(List<dynamic> messages) {
    print('Grouping messages by date...');
    final groupedMessages = <String, List<dynamic>>{};

    for (final message in messages) {
      final dateStr = DateFormat('yyyy-MM-dd').format(message.timestamp);
      if (!groupedMessages.containsKey(dateStr)) {
        groupedMessages[dateStr] = [];
      }
      groupedMessages[dateStr]!.add(message);
    }

    print('Messages grouped by date: ${groupedMessages.keys}');
    return groupedMessages;
  }

  String getReadableDate(String dateStr) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    if (dateStr == today) {
      return 'Today';
    } else if (dateStr == yesterday) {
      return 'Yesterday';
    } else {
      final date = DateFormat('yyyy-MM-dd').parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  @override
  void dispose() {
    print('Disposing ChatScreenNotifier...');
    state.textController.dispose();
    state.scrollController.dispose();
    super.dispose();
  }
}

final chatScreenProvider =
    StateNotifierProvider<ChatScreenNotifier, ChatScreenState>((ref) {
  return ChatScreenNotifier(ref);
});

// Placeholder for getRoomName function (should be implemented based on your logic)
String getRoomName(String userId1, String userId2) {
  final ids = [userId1, userId2]..sort();
  return '${ids[0]}_${ids[1]}';
}
