// Create a new file: chat_screen_wrapper.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../../presentation/pages/chat_screen/chat_screen.dart';
import 'navigation_service.dart';
import 'notification_service.dart';


class ChatScreenWrapper extends StatefulWidget {
  final AppUser receiver;

  const ChatScreenWrapper({super.key, required this.receiver});

  @override
  State<ChatScreenWrapper> createState() => _ChatScreenWrapperState();
}

class _ChatScreenWrapperState extends State<ChatScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // Set current chat user when entering
    NavigationService.setCurrentChatUser(widget.receiver.uuid);
    // Clear notifications for this user
    NotificationService.clearNotificationsForUser(widget.receiver.uuid);
  }

  @override
  void dispose() {
    // Clear current chat user when leaving
    NavigationService.setCurrentChatUser(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatScreen(receiver: widget.receiver);
  }
}