import 'package:flutter/material.dart';

class Messagebox extends StatelessWidget {
  final String text;
  final bool isUser;
  final String senderId;
  final String recipientId;
  final DateTime timestamp;

  Messagebox({
    required this.text,
    required this.senderId,
    required this.recipientId,
    required this.timestamp,
    required this.isUser,
  });
  // Existing fields and methods

  // Define the toMessagebox method
  Messagebox toMessagebox() {
    // Convert ChatMessage to Messagebox
    return Messagebox(
      isUser: this.isUser,
      recipientId: this.recipientId,
      // Map the fields from ChatMessage to Messagebox
      text: this.text,
      timestamp: this.timestamp,
      senderId: this.senderId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // final userBubbleColor = isDarkMode ? Colors.blue[700] : Colors.blue[100];
    // final reciverBubbleColor = isDarkMode ? Color.fromRGBO(255, 133, 102, 1.0) : Colors.grey[300];
    final textColor = isDarkMode ? Colors.white : Colors.black;

    final userBubbleGradient = isDarkMode 
    ? LinearGradient(
        colors: [Colors.blue[800]!, Colors.blue[600]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      )
    : LinearGradient(
        colors: [Colors.blue[50]!, Colors.blue[100]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

final receiverBubbleGradient = isDarkMode 
    ? LinearGradient(
        colors: [
          Color.fromRGBO(255, 133, 102, 1.0), // Orange
          Color.fromRGBO(255, 107, 107, 1.0), // Coral/Pink
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      )
    : LinearGradient(
        colors: [
          Color.fromRGBO(255, 178, 102, 1.0), // Lighter orange
          Color.fromRGBO(255, 149, 149, 1.0), // Lighter coral
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.assistant, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
             decoration: BoxDecoration(
  gradient: isUser ? userBubbleGradient : receiverBubbleGradient,
  borderRadius: BorderRadius.only(
    topLeft: const Radius.circular(16),
    topRight: const Radius.circular(16),
    bottomLeft: Radius.circular(isUser ? 16 : 0),
    bottomRight: Radius.circular(isUser ? 0 : 16),
  ),
),
              child: isUser
                  ? Text(
                      text,
                      style: TextStyle(color: textColor),
                    )
                  : Text(
                      text,
                      style: TextStyle(color: textColor),
                    ),
            ),
          ),
          if (isUser) ...[
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
