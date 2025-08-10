import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// import 'dart:convert';

import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';
import '../home_screen/home_provider.dart';

class ChatScreenState {
  final String roomName;
  final String currentUserUuid;
  final AppUser receiver;
  final TextEditingController textController;
  final ScrollController scrollController;
  final String? errorMessage;
  final bool isLoading;
  final List<ChatMessage> messages;
  final bool isInitialized;

  ChatScreenState({
    required this.roomName,
    required this.currentUserUuid,
    required this.receiver,
    required this.textController,
    required this.scrollController,
    this.errorMessage,
    required this.isLoading,
    required this.messages,
    this.isInitialized = false,
  });

  ChatScreenState copyWith({
    String? roomName,
    String? currentUserUuid,
    AppUser? receiver,
    TextEditingController? textController,
    ScrollController? scrollController,
    String? errorMessage,
    bool? isLoading,
    List<ChatMessage>? messages,
    bool? isInitialized,
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
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class ChatScreenNotifier extends StateNotifier<ChatScreenState> {
  final Ref ref;
  final String receiverUuid;

  ChatScreenNotifier(this.ref, this.receiverUuid)
      : super(ChatScreenState(
          roomName: '',
          currentUserUuid: '',
          receiver: AppUser(
            uuid: '',
            name: '',
            surname: '',
            profilePic: '',
            lastSeen: DateTime.now(),
            email: '',
            username: '',
            bio: '',
            dateOfBirth: '',
            gender: '',
            phoneNumber: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          textController: TextEditingController(),
          scrollController: ScrollController(),
          isLoading: false,
          messages: [],
          isInitialized: false,
        )) {
    // Defer initialization to avoid provider modification during initialization
    Future.microtask(() => _initializeChat());
  }

  void _initializeChat() async {
    if (state.isInitialized) return;

    try {
      print('Initializing chat for receiver: $receiverUuid');
      final authProvider = ref.read(authServiceProvider);
      final currentUserUuid = authProvider.currentUser?.uid ?? '';

      // Find the receiver from the fetched users
      final homeState = ref.read(homeScreenProvider);
      final receiver = homeState.fetchedUsers.firstWhere(
        (user) => user.uuid == receiverUuid,
        orElse: () => throw Exception('Receiver not found'),
      );

      final roomName = getRoomName(currentUserUuid, receiver.uuid);
      final webSocketService = ref.read(webSocketServiceProvider);

      if (!webSocketService.isConnected) {
        print('WebSocket not connected. Attempting to connect...');
        webSocketService.connect(
            // 'wss://chatterg-go-production.up.railway.app/ws?userID=$currentUserUuid');
  //  'wss://abfcbf7ad979.ngrok-free.app/ws?userID=$currentUserUuid');
   '${dotenv.env['WEBSOCKET_URL']}/ws?userID=$currentUserUuid');

      }

      // Load local messages from ObjectBox
      final localMessages =
          objectBox.getMessagesFor(currentUserUuid, receiver.uuid);

      // Update state first
      state = state.copyWith(
        messages: localMessages,
        currentUserUuid: currentUserUuid,
        receiver: receiver,
        roomName: roomName,
        isInitialized: true,
      );

      // Then update the chat messages provider using Future.microtask
      Future.microtask(() {
        ref.read(chatMessagesProvider.notifier).state = {
          roomName: localMessages,
        };
      });

      print(
          'Chat initialized with roomName: $roomName for receiver: ${receiver.name}');

      // Scroll to bottom after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Watch messages for the room
      ref.listen(chatMessagesProvider, (previous, next) {
        if (!mounted) return;

        final messages = next[roomName] ?? [];
        print('New messages received for room $roomName: ${messages.length}');

        if (mounted) {
          state = state.copyWith(messages: messages);

          // Scroll to bottom when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      });
    } catch (e) {
      print('Error initializing chat: $e');
      if (mounted) {
        state = state.copyWith(
          errorMessage: 'Error initializing chat: $e',
          isInitialized: true,
        );
      }
    }
  }

  final Map<String, void Function(ChatMessage)> _roomListeners = {};

  void registerRoomListener(
      String roomName, void Function(ChatMessage) callback) {
    _roomListeners[roomName] = callback;
  }

  void unregisterRoomListener(String roomName) {
    _roomListeners.remove(roomName);
  }

  void markAsRead(ChatMessage message) {
    if (!mounted) return;

    final updatedMessages = state.messages.map((m) {
      if (m.timestamp == message.timestamp && m.senderId == message.senderId) {
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

    // Notify the server to mark the message as read
    final webSocketService = ref.read(webSocketServiceProvider);
    webSocketService.markAsRead(message.timestamp, message.senderId);
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
    if (state.isLoading || text.trim().isEmpty || !mounted) return;

    state = state.copyWith(isLoading: true);

    try {
      final webSocketService = ref.read(webSocketServiceProvider);
      if (!webSocketService.isConnected) {
        throw Exception('WebSocket not connected');
      }

      print('Sending message with text: ${text.trim()}');
      print('Current user UUID: ${state.currentUserUuid}');
      print('Receiver UUID: ${state.receiver.uuid}');

      webSocketService.sendChatMessage(state.receiver.uuid, text.trim());

      final message = ChatMessage(
        senderId: state.currentUserUuid,
        recipientId: state.receiver.uuid,
        content: text.trim(),
        timestamp: DateTime.now().toIso8601String(),
        // isRead: false,
      );

      print('Created local message: ${message.toJson()}');

      ref.read(chatMessagesProvider.notifier).addMessage(message);

      print('Message sent successfully');
      state.textController.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Failed to send message: $e');
      if (mounted) {
        state = state.copyWith(errorMessage: 'Failed to send message: $e');
      }
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Map<String, List<ChatMessage>> groupMessagesByDate(
      List<ChatMessage> messages) {
    final groupedMessages = <String, List<ChatMessage>>{};
    for (final message in messages) {
      DateTime messageDate;
      try {
        // Always parse as UTC then convert to local
        messageDate = DateTime.parse(message.timestamp).toUtc().toLocal();
      } catch (e) {
        messageDate = DateTime.now();
      }
      // Format date from local DateTime
      final dateStr = DateFormat('yyyy-MM-dd').format(messageDate);
      if (!groupedMessages.containsKey(dateStr)) {
        groupedMessages[dateStr] = [];
      }
      groupedMessages[dateStr]!.add(message);
    }
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
  
  // Add this method to ChatScreenNotifier class
void sendImageMessage(String base64Image, String fileType) {
  if (state.isLoading || !mounted) return;

  state = state.copyWith(isLoading: true);
  try {
    final webSocketService = ref.read(webSocketServiceProvider);
    if (!webSocketService.isConnected) {
      throw Exception('WebSocket not connected');
    }

    print('Sending image message');
    print('Current user UUID: ${state.currentUserUuid}');
    print('Receiver UUID: ${state.receiver.uuid}');
    print('File type: $fileType');
    print('Image size: ${base64Image.length} characters');

    webSocketService.sendImageMessage(state.receiver.uuid, base64Image, fileType);

    // Create local image message
    final message = ChatMessage(
      senderId: state.currentUserUuid,
      recipientId: state.receiver.uuid,
      content: base64Image,
      timestamp: DateTime.now().toIso8601String(),
      messageType: 'image',
      fileType: fileType,
    );

    print('Created local image message: ${message.toJson()}');
    
    // Add to chat messages provider
    ref.read(chatMessagesProvider.notifier).addMessage(message);
    
    print('Image message sent successfully');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

  } catch (e) {
    print('Failed to send image message: $e');
    if (mounted) {
      state = state.copyWith(errorMessage: 'Failed to send image: $e');
    }
  } finally {
    if (mounted) {
      state = state.copyWith(isLoading: false);
    }
  }
}


  @override
  void dispose() {
    print('Disposing ChatScreenNotifier for receiver: $receiverUuid');
    state.textController.dispose();
    state.scrollController.dispose();
    super.dispose();
  }
}

// Family provider that creates a separate instance for each receiver
final chatScreenProvider =
    StateNotifierProvider.family<ChatScreenNotifier, ChatScreenState, String>(
        (ref, receiverUuid) {
  return ChatScreenNotifier(ref, receiverUuid);
});

// Placeholder for getRoomName function
String getRoomName(String userId1, String userId2) {
  final ids = [userId1, userId2]..sort();
  return '${ids[0]}_${ids[1]}';
}
