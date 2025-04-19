import 'package:flutter/material.dart';

import '../../widgets/message_box.dart';
import '../chat_screen/chat_screen.dart';
import '../profile_screen/ProfileScreen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _chatrooms = {};
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // _loadChatrooms();
  }

  @override
  Widget build(BuildContext context) {
    var isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Godzilla',
          style: TextStyle(
            fontSize: 24,
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()));
            },
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Your Conversations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'The chats will be stored locally on your device',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            Expanded(
              child: _chatrooms.isEmpty
                  ? Center(
                      child: Text(
                        'No conversations yet.\nTap + to start a new chat!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chatrooms.length,
                      itemBuilder: (context, index) {
                        final roomName = _chatrooms.keys.elementAt(index);
                        final lastMessage = _chatrooms[roomName]!.isNotEmpty
                            ? _chatrooms[roomName]!.last.text
                            : 'No messages yet';
                        return Dismissible(
                          key: Key(roomName),
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            setState(() {
                              _chatrooms.remove(roomName);
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$roomName deleted')),
                            );
                          },
                          child: ListTile(
                            title: Text(
                              roomName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: Text(
                                roomName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  reciver: "user2",
                                  messages: [
                                    ChatMessage(
                                      text: "hello",
                                      isUser: false,
                                    )
                                  ],
                                  onMessagesUpdated: (updatedMessages) {
                                    // Handle updated messages here
                                  },
                                ),
                              ),
                            ),
                            onLongPress: () => {},
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Create new chat',
        child: const Icon(Icons.add),
      ),
    );
  }
}
