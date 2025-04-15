import 'package:flutter/material.dart';

import '../../widgets/message_box.dart';

class ChatScreen extends StatefulWidget {
  final String reciver;
  final List<ChatMessage> messages;
  final Function(List<ChatMessage>) onMessagesUpdated;

  const ChatScreen({
    super.key,
    required this.reciver,
    required this.messages,
    required this.onMessagesUpdated,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  // final gemini = Gemini.instance;
  final bool _isLoading = false;
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = widget.messages;
    if (_messages.isEmpty) {
      _messages.add(const ChatMessage(
        text: "Good evening, how can I assist you today?",
        isUser: false,
      ));
    }
  }

  Future<void> _sendMessage() async {
    // if (_textController.text.isEmpty) return;

    // final userMessage = _textController.text;
    // setState(() {
    //   _messages.add(ChatMessage(
    //     text: userMessage,
    //     isUser: true,
    //   ));
    //   _isLoading = true;
    // });

    // widget.onMessagesUpdated(_messages);
    // _textController.clear();
    // _scrollToBottom();

    // String prompt = '''
    // Previous conversation:
    // ${_messages.map((msg) => "${msg.isUser ? 'User' : 'AI'}: ${msg.text}").join('\n')}

    // User: $userMessage

    // Please continue the conversation based on the context above. Respond as an AI assistant.
    // ''';

    // try {
    //   final response = await gemini.text(prompt);
    //   setState(() {
    //     _messages.add(ChatMessage(
    //       text: response?.content?.parts?.last.text ??
    //           'Sorry, I could not process that.',
    //       isUser: false,
    //     ));
    //     _isLoading = false;
    //   });
    //   widget.onMessagesUpdated(_messages);
    // } catch (e) {
    //   setState(() {
    //     _messages.add(const ChatMessage(
    //       text: 'An error occurred. Please try again.',
    //       isUser: false,
    //     ));
    //     _isLoading = false;
    //   });
    //   widget.onMessagesUpdated(_messages);
    // }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          widget.reciver,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call), onPressed: () {}
              // Navigator.of(context).push(MaterialPageRoute(
              //   builder: (context) => const AILiveCallScreen(),
              ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _messages[index];
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(),
              ),
            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Chat with Pikachu',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800] : Colors.white,
                          hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
