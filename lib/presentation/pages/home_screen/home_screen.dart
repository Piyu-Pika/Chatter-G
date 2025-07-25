import 'package:chatterg/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/datasources/remote/api_value.dart';
import '../../../data/datasources/remote/chat_screen_wrapper.dart';
import '../../../data/datasources/remote/notification_service.dart';
import '../../../data/models/user_model.dart';
import '../camera_screen/camera_screen.dart';
import '../chat_screen/chat_screen.dart';
import '../pending_request_screen/pending_request_screen.dart';
import '../profile_screen/ProfileScreen.dart';
import '../serach_friend/search_friend_screen.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  late AnimationController _pageTransitionController;
  late Animation<double> _pageTransition;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initializeNotifications(
          FirebaseAuth.instance.currentUser!, // Ensure you pass a valid user
        ));

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));

    _pageTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pageTransition = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageTransitionController,
      curve: Curves.easeInOutCubic,
    ));

    _fabAnimationController.forward();
    _pageTransitionController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _pageTransitionController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    final currentIndex = ref.read(bottomNavProvider);
    if (currentIndex != index) {
      // Animate page transition
      _pageTransitionController.reset();
      ref.read(bottomNavProvider.notifier).state = index;
      _pageTransitionController.forward();
    }
  }

  Future<void> _initializeNotifications(User firebaseUser) async {
    try {
      final uuid = firebaseUser.uid;
      final userModel = await ApiClient().getUserByUUID(uuid: uuid);

      // Assuming your userModel includes uuid, etc.
      final user = AppUser.fromJson(userModel);
      final token = await firebaseUser.getIdToken();

      await NotificationService.initialize(user, authToken: token ?? '');
      debugPrint('Notifications initialized and FCM token sent to server');
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavProvider);
    final homeState = ref.watch(homeScreenProvider);
    final homeNotifier = ref.read(homeScreenProvider.notifier);

    // List of pages
    final pages = [
      ChatCameraScreen(),
      _buildChatScreen(homeState, homeNotifier),
      _buildChatterGScreen(homeState, homeNotifier),
      _buildCallLogsScreen(),
    ];

    return Scaffold(
      key: homeNotifier.scaffoldKey,
      extendBody: true,
      appBar: _buildAnimatedAppBar(context, selectedIndex),
      body: AnimatedBuilder(
        animation: _pageTransition,
        builder: (context, child) {
          return FadeTransition(
            opacity: _pageTransition,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(_pageTransition),
              child: IndexedStack(
                index: selectedIndex,
                children: pages,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(selectedIndex),
      floatingActionButton: selectedIndex == 1
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SearchFriendScreen()));
                },
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child:
                    const Icon(Icons.add_comment_rounded, color: Colors.white),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar(
      BuildContext context, int selectedIndex) {
    final titles = ['Camera', 'Chats', 'ChatterG', 'Call Logs'];
    final icons = [
      Icons.camera_alt_rounded,
      Icons.chat_bubble_rounded,
      Icons.chat_rounded,
      Icons.call_rounded,
    ];

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: context.backgroundGradient,
        ),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Row(
          key: ValueKey(selectedIndex),
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icons[selectedIndex],
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              titles[selectedIndex],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (selectedIndex == 1) ...[
          IconButton(
              icon: Icon(Icons.notifications_rounded),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PendingRequestScreen()));
              }),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
            onPressed: () async {
              await ref.read(homeScreenProvider.notifier).signOut(context);
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNavigationBar(int selectedIndex) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(8, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.white.withOpacity(0.8),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: SalomonBottomBar(
            currentIndex: selectedIndex,
            onTap: _onBottomNavTap,
            backgroundColor: Colors.transparent,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.5),
            selectedColorOpacity: 0.1,
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            items: [
              SalomonBottomBarItem(
                icon: const Icon(Icons.camera_alt_rounded, size: 24),
                title: const Text("Camera",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                selectedColor: Theme.of(context).colorScheme.primary,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.chat_bubble_rounded, size: 24),
                title: const Text("Chats",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                selectedColor: Theme.of(context).colorScheme.primary,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.chat_rounded, size: 24),
                title: const Text("ChatterG",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                selectedColor: Theme.of(context).colorScheme.primary,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.call_rounded, size: 24),
                title: const Text("Calls",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                selectedColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatScreen(dynamic homeState, dynamic homeNotifier) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: homeState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: homeNotifier.refreshChatrooms,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Recent Chats',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: homeState.fetchedUsers.isEmpty
                          ? _buildEmptyState(
                              'No chats yet.\nStart a conversation!')
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: homeState.fetchedUsers.length,
                              itemBuilder: (context, index) {
                                final user = homeState.fetchedUsers[index];
                                return _buildChatTile(user);
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildChatterGScreen(dynamic homeState, dynamic homeNotifier) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Text(
          'ChatterG Screen - Coming Soon!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildCallLogsScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.call_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Call Logs',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Call history coming soon!',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(dynamic user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: const Text(
          'Tap to start chatting',
          style: TextStyle(color: Colors.grey),
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: context.buttonGradient,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              user.name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 16,
        ),
        onTap: () {
          ref.read(currentReceiverProvider.notifier).state = user;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreenWrapper(receiver: user),
            ),
          );
        },
      ),
    );
  }
}
// Widget _buildConversationTile(dynamic user) {
//   return Container(
//     margin: const EdgeInsets.only(bottom: 12),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       boxShadow: [
//         BoxShadow(
//           color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
//           blurRadius: 8,
//           offset: const Offset(0, 2),
//         ),
//       ],
//     ),
//     child: ListTile(
//       contentPadding: const EdgeInsets.all(16),
//       title: Text(
//         user.name,
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//         ),
//       ),
//       subtitle: const Text(
//         'No messages yet',
//         style: TextStyle(color: Colors.grey),
//       ),
//       leading: CircleAvatar(
//         radius: 25,
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         child: Text(
//           user.name[0].toUpperCase(),
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//       ),
//       trailing: Icon(
//         Icons.arrow_forward_ios_rounded,
//         color: Theme.of(context).colorScheme.primary,
//         size: 16,
//       ),
//       onTap: () {
//         ref.read(currentReceiverProvider.notifier).state = user;
//         Navigator.push(
//           context,
//           MaterialPageRoute(builder: (context) => const ChatScreen()),
//         );
//       },
//     ),
//   );
// }
