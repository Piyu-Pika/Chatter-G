import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// import 'dart:convert';

import '../../../data/datasources/remote/api_value.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_model.dart';
import '../../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';
import '../home_screen/home_provider.dart';
import 'package:dev_log/dev_log.dart';


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
  final ApiClient _apiClient = ApiClient();

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
      L.i('Initializing chat for receiver: $receiverUuid');
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
        L.i('WebSocket not connected. Attempting to connect...');
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

      L.i(
          'Chat initialized with roomName: $roomName for receiver: ${receiver.name}');

      // Scroll to bottom after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Watch messages for the room
      ref.listen(chatMessagesProvider, (previous, next) {
        if (!mounted) return;

        final messages = next[roomName] ?? [];
        L.i('New messages received for room $roomName: ${messages.length}');

        if (mounted) {
          state = state.copyWith(messages: messages);

          // Scroll to bottom when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      });
    } catch (e) {
      L.e('Error initializing chat: $e');
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

  void updateMessagesDirectly(List<ChatMessage> messages) {
  if (mounted) {
    state = state.copyWith(messages: messages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
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
      L.i('Scrolling to bottom...');
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

    L.i('Sending message with text: ${text.trim()}');
    L.i('Current user UUID: ${state.currentUserUuid}');
    L.i('Receiver UUID: ${state.receiver.uuid}');
    
    // Create local message first
    final message = ChatMessage(
      senderId: state.currentUserUuid,
      recipientId: state.receiver.uuid,
      content: text.trim(),
      timestamp: DateTime.now().toIso8601String(),
    );

    L.i('Created local message: ${message.toJson()}');
    
    // Add to local state immediately for instant display
    final currentMessages = List<ChatMessage>.from(state.messages);
    currentMessages.add(message);
    currentMessages.sort((a, b) {
      try {
        final aTime = DateTime.parse(a.timestamp);
        final bTime = DateTime.parse(b.timestamp);
        return aTime.compareTo(bTime);
      } catch (e) {
        return 0;
      }
    });
    
    // Update local state first
    state = state.copyWith(messages: currentMessages);
    
    // Then send via WebSocket
    webSocketService.sendChatMessage(state.receiver.uuid, text.trim());
    
    // Add to WebSocket provider for other participants
    ref.read(chatMessagesProvider.notifier).addMessage(message);
    
    L.i('Message sent successfully');
    state.textController.clear();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
  } catch (e) {
    L.e('Failed to send message: $e');
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

  // Add these methods to ChatScreenNotifier class
void refreshMessages() {
  final roomMessages = ref.read(chatMessagesProvider)[state.roomName] ?? [];
  if (mounted) {
    state = state.copyWith(messages: roomMessages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
}

void forceRefresh() {
  // Refresh from both WebSocket provider and local database
  final localMessages = objectBox.getMessagesFor(state.currentUserUuid, state.receiver.uuid);
  final webSocketMessages = ref.read(chatMessagesProvider)[state.roomName] ?? [];
  
  // Merge and deduplicate
  final allMessages = <ChatMessage>[];
  final messageMap = <String, ChatMessage>{};
  
  for (final msg in [...localMessages, ...webSocketMessages]) {
    final key = '${msg.senderId}_${msg.timestamp}_${msg.content}';
    messageMap[key] = msg;
  }
  
  allMessages.addAll(messageMap.values);
  allMessages.sort((a, b) {
    try {
      final aTime = DateTime.parse(a.timestamp);
      final bTime = DateTime.parse(b.timestamp);
      return aTime.compareTo(bTime);
    } catch (e) {
      return 0;
    }
  });
  
  if (mounted) {
    state = state.copyWith(messages: allMessages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
}

  
  // Enhanced sendImageMessage method in chat_provider.dart
Future<void> sendImageMessage(File imageFile) async {
  if (state.isLoading || !mounted) return;
  
  state = state.copyWith(isLoading: true);
  
  try {
    L.i('Sending image message via HTTP');
    L.i('Current user UUID: ${state.currentUserUuid}');
    L.i('Receiver UUID: ${state.receiver.uuid}');
    L.i('Image path: ${imageFile.path}');

    // Send image via HTTP API
    final response = await _apiClient.sendImageMessage(
      userUuid: state.currentUserUuid,
      receiverId: state.receiver.uuid,
      imageFile: imageFile,
    );

    L.i('Image sent successfully: $response');
    
    // Create local message immediately
    final message = ChatMessage(
      senderId: state.currentUserUuid,
      recipientId: state.receiver.uuid,
      content: response['data']['message_id'], // Store the returned message ID
      timestamp: DateTime.now().toIso8601String(),
      messageType: 'image',
      fileType: imageFile.path.split('.').last.toLowerCase(),
    );

    L.i('Created local image message: ${message.toJson()}');
    
    // CRITICAL: Update local state FIRST for immediate UI response
    final currentMessages = List<ChatMessage>.from(state.messages);
    currentMessages.add(message);
    currentMessages.sort((a, b) {
      try {
        final aTime = DateTime.parse(a.timestamp);
        final bTime = DateTime.parse(b.timestamp);
        return aTime.compareTo(bTime);
      } catch (e) {
        return 0;
      }
    });
    
    // Update local state immediately - this triggers UI rebuild
    state = state.copyWith(messages: currentMessages);
    
    // THEN add to WebSocket provider for other participants
    ref.read(chatMessagesProvider.notifier).addMessage(message);
    
    L.i('Image message sent successfully via HTTP and state updated');
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
  } catch (e) {
    L.e('Failed to send image message: $e');
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
    L.e('Disposing ChatScreenNotifier for receiver: $receiverUuid');
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
