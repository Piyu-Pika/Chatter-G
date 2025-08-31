import 'dart:convert';

import 'package:flutter/material.dart';
import 'image_message_box.dart';
import 'package:dev_log/dev_log.dart';


class Messagebox extends StatelessWidget {
  final String text;
  final bool isUser;
  final String senderId;
  final String recipientId;
  final DateTime timestamp;
  final String? messageType;
  final String? fileType;
  
  const Messagebox({
    super.key,
    required this.text,
    required this.senderId,
    required this.recipientId,
    required this.timestamp,
    required this.isUser,
    this.messageType,
    this.fileType,
  });

  // FIXED: Better image message detection
  bool get isImageMessage {
    // First check the explicit message type
    if (messageType == 'image') {
      L.i('Message detected as image via messageType field');
      return true;
    }
    
    // Then check if content looks like base64 image
    if (_isBase64Image(text)) {
      L.i('Message detected as image via base64 content analysis');
      return true;
    }
    
    L.i('Message detected as text message');
    return false;
  }

  // FIXED: Improved base64 image detection
  bool _isBase64Image(String content) {
    try {
      // Check length - base64 images should be substantial
      if (content.length < 200 || content.length > 20000000) {
        return false;
      }
      
      // Check if it starts with common data URL formats
      if (content.startsWith('data:image/')) {
        return true;
      }
      
      // Check base64 pattern - more lenient
      final base64Pattern = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
      if (!base64Pattern.hasMatch(content)) {
        return false;
      }
      
      // Additional check: try to decode a small portion
      try {
        final testPortion = content.length > 500 ? content.substring(0, 500) : content;
        final decoded = base64Decode(testPortion);
        
        // Check for image file signatures in first few bytes
        if (decoded.length >= 4) {
          // PNG signature: 89 50 4E 47
          if (decoded[0] == 0x89 && decoded[1] == 0x50 && decoded[2] == 0x4E && decoded[3] == 0x47) {
            return true;
          }
          // JPEG signature: FF D8
          if (decoded[0] == 0xFF && decoded[1] == 0xD8) {
            return true;
          }
          // GIF signature: 47 49 46
          if (decoded[0] == 0x47 && decoded[1] == 0x49 && decoded[2] == 0x46) {
            return true;
          }
        }
      } catch (e) {
        // If base64 decode fails, it's not a valid image
        return false;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    L.i('Building message widget - isImage: $isImageMessage, messageType: $messageType, contentLength: ${text.length}');
    
    // If this is an image message, use the optimized image widget
    if (isImageMessage) {
      return ImageMessageBox(
        base64Image: text,
        isUser: isUser,
        senderId: senderId,
        recipientId: recipientId,
        timestamp: timestamp,
        fileType: fileType,
      );
    }

    // Regular text message
    return _buildTextMessage(context);
  }

  Widget _buildTextMessage(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
              Color.fromRGBO(255, 133, 102, 1.0),
              Color.fromRGBO(255, 107, 107, 1.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              Color.fromRGBO(255, 178, 102, 1.0),
              Color.fromRGBO(255, 149, 149, 1.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth * 0.75;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
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
                    child: Text(
                      text,
                      style: TextStyle(color: textColor),
                    ),
                  ),
                );
              },
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
