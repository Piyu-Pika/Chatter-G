import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/remote/cockroachdb_data_source.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/message_box.dart';
import '../chat_screen/chat_screen.dart';
import '../profile_screen/ProfileScreen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final Map<String, List<ChatMessage>> _chatrooms = {};
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  String _currentUserUuid = '';

  @override
  void initState() {
    super.initState();
    _loadChatrooms();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    final authProvider =
        ref.read(authServiceProvider); // Assuming authProvider is defined
    final userId = await authProvider.getUid();
    setState(() {
      _currentUserUuid = userId;
    });
  }

  Future<void> _loadChatrooms() async {
    try {
      // Simulate fetching users from CockroachDB
      CockroachDBDataSource cockroachDBDataSource = CockroachDBDataSource();
      final users = await cockroachDBDataSource.getData(_currentUserUuid);
      setState(() {
        for (var user in users) {
          _chatrooms[user.name] = [];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  Future<void> _refreshChatrooms() async {
    setState(() {
      _isLoading = true;
    });
    await _loadChatrooms();
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
          'Chatter G',
          style: TextStyle(
            fontSize: 24,
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut(context);

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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refreshChatrooms,
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
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _chatrooms.length,
                              itemBuilder: (context, index) {
                                final roomName =
                                    _chatrooms.keys.elementAt(index);
                                final lastMessage =
                                    _chatrooms[roomName]!.isNotEmpty
                                        ? _chatrooms[roomName]!.last.text
                                        : 'No messages yet';
                                return Dismissible(
                                  key: Key(roomName),
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) {
                                    setState(() {
                                      _chatrooms.remove(roomName);
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('$roomName deleted')),
                                    );
                                  },
                                  child: ListTile(
                                    title: Text(
                                      roomName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
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
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          reciver: roomName,
                                          messages: _chatrooms[roomName]!,
                                          onMessagesUpdated: (updatedMessages) {
                                            setState(() {
                                              _chatrooms[roomName] =
                                                  updatedMessages;
                                            });
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Create new chat',
        child: const Icon(Icons.add),
      ),
    );
  }
}
