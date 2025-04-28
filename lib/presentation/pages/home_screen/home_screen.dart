import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../chat_screen/chat_screen.dart';
import '../profile_screen/ProfileScreen.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeScreenProvider);
    final homeNotifier = ref.read(homeScreenProvider.notifier);
    // final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: homeNotifier.scaffoldKey,
      // backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        // backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Chatter G',
          style: TextStyle(
            fontSize: 24,
            // color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await homeNotifier.signOut(context);
            },
            // color: isDarkMode ? Colors.white : Colors.black,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
            // color: isDarkMode ? Colors.white : Colors.black,
          ),
        ],
      ),
      body: SafeArea(
        child: homeState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: homeNotifier.refreshChatrooms,
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
                          // color: isDarkMode ? Colors.white : Colors.black,
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
                      child: homeState.fetchedUsers.isEmpty
                          ? Center(
                              child: Text(
                                'No conversations yet.\nTap + to start a new chat!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  // color: isDarkMode
                                  //     ? Colors.white70
                                  //     : Colors.black54,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: homeState.fetchedUsers.length,
                              itemBuilder: (context, index) {
                                final user = homeState.fetchedUsers[index];
                                return ListTile(
                                  title: Text(
                                    user.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      // color: isDarkMode
                                      //     ? Colors.white
                                      //     : Colors.black,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'No messages yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      user.name[0].toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  onTap: () {
                                    ref
                                        .read(currentReceiverProvider.notifier)
                                        .state = user;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ChatScreen(),
                                      ),
                                    );
                                  },
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
