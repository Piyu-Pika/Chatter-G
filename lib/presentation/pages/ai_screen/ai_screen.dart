import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/image_message_box.dart';
import 'ai_provider.dart';

class AIMessageBox extends StatelessWidget {
  final AIChatMessage message;

  const AIMessageBox({
    super.key,
    required this.message,
  });

  bool get isImageMessage {
    return message.messageType == 'image';
  }

  @override
  Widget build(BuildContext context) {
    if (isImageMessage) {
      return ImageMessageBox(
        base64Image: message.content,
        isUser: message.isUser,
        senderId: message.isUser ? 'user' : 'ai',
        recipientId: message.isUser ? 'ai' : 'user',
        timestamp: message.timestamp,
        fileType: message.fileType,
      );
    }

    return _buildTextMessage(context);
  }

  Widget _buildTextMessage(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    
    final userBubbleGradient = isDarkMode
        ? const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final aiBubbleGradient = isDarkMode
        ? const LinearGradient(
            colors: [Color(0xFF424242), Color(0xFF616161)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth * 0.75;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: message.isUser ? userBubbleGradient : aiBubbleGradient,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(message.isUser ? 16 : 0),
                        bottomRight: Radius.circular(message.isUser ? 0 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
