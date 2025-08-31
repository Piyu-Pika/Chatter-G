import 'package:chatterg/data/datasources/remote/ai_data_source.dart' show GeminiService;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class AIChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? messageType;
  final String? fileType;
  final String? currentUserUuid;


  AIChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.messageType,
    this.fileType,
    this.currentUserUuid,
  });
}

class AIChatState {
  final List<AIChatMessage> messages;
  final bool isLoading;
  final String? errorMessage;
  final TextEditingController textController;
  final ScrollController scrollController;
  final List<Content> chatHistory;

  AIChatState({
    required this.messages,
    required this.isLoading,
    this.errorMessage,
    required this.textController,
    required this.scrollController,
    required this.chatHistory,
  });

  AIChatState copyWith({
    List<AIChatMessage>? messages,
    bool? isLoading,
    String? errorMessage,
    TextEditingController? textController,
    ScrollController? scrollController,
    List<Content>? chatHistory,
  }) {
    return AIChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      textController: textController ?? this.textController,
      scrollController: scrollController ?? this.scrollController,
      chatHistory: chatHistory ?? this.chatHistory,
    );
  }
}

class AIChatNotifier extends StateNotifier<AIChatState> {
  final GeminiService _geminiService;
  
  AIChatNotifier(this._geminiService) : super(AIChatState(
    messages: [],
    isLoading: false,
    textController: TextEditingController(),
    scrollController: ScrollController(),
    chatHistory: [],
  ));

  void addWelcomeMessage() {
    final welcomeMessage = AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: "Hello! I'm your AI assistant powered by Gemini. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(
      messages: [welcomeMessage],
    );
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty || state.isLoading) return;

    final userMessage = AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Add user message
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    // Clear text field
    state.textController.clear();

    // Scroll to bottom
    _scrollToBottom();

    try {
      // Update chat history with user message
      final updatedHistory = [
        ...state.chatHistory,
        Content.text(message),
      ];

      // Get AI response
      final response = await _geminiService.sendMessage(message, history: updatedHistory);

      final aiMessage = AIChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // Add AI response and update history
      final finalHistory = [
        ...updatedHistory,
        Content.model([TextPart(response)]),
      ];

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
        chatHistory: finalHistory,
      );

      _scrollToBottom();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get AI response: $e',
      );
    }
  }

  Future<void> sendImageMessage(String prompt, Uint8List imageBytes, String fileExtension) async {
    if (state.isLoading) return;

    final userMessage = AIChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: imageBytes.toString(), // This will be handled by your image message widget
      isUser: true,
      timestamp: DateTime.now(),
      messageType: 'image',
      fileType: fileExtension,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    _scrollToBottom();

    try {
      final response = await _geminiService.sendImageMessage(
        prompt.isEmpty ? "What's in this image?" : prompt,
        imageBytes,
        history: state.chatHistory,

      );

      final aiMessage = AIChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );

      _scrollToBottom();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to analyze image: $e',
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.scrollController.hasClients) {
        state.scrollController.animateTo(
          state.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Map<String, List<AIChatMessage>> groupMessagesByDate(List<AIChatMessage> messages) {
    final Map<String, List<AIChatMessage>> grouped = {};
    
    for (final message in messages) {
      final dateKey = DateFormat('yyyy-MM-dd').format(message.timestamp);
      if (grouped.containsKey(dateKey)) {
        grouped[dateKey]!.add(message);
      } else {
        grouped[dateKey] = [message];
      }
    }
    
    return grouped;
  }

  String getReadableDate(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  @override
  void dispose() {
    state.textController.dispose();
    state.scrollController.dispose();
    super.dispose();
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

final aiChatProvider = StateNotifierProvider<AIChatNotifier, AIChatState>(
  (ref) => AIChatNotifier(ref.read(geminiServiceProvider)),
);
