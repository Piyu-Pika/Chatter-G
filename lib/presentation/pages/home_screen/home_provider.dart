import 'package:chatterg/data/datasources/remote/api_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/remote/cockroachdb_data_source.dart';
import '../../../data/models/user_model.dart' as User;
import '../../providers/auth_provider.dart';
import '../../providers/websocket_provider.dart';

class HomeScreenState {
  final Map<String, List<dynamic>> chatrooms;
  final bool isLoading;
  final String currentUserUuid;
  final List<User.User> fetchedUsers;

  HomeScreenState({
    required this.chatrooms,
    required this.isLoading,
    required this.currentUserUuid,
    required this.fetchedUsers,
  });

  HomeScreenState copyWith({
    Map<String, List<dynamic>>? chatrooms,
    bool? isLoading,
    String? currentUserUuid,
    List<User.User>? fetchedUsers,
  }) {
    return HomeScreenState(
      chatrooms: chatrooms ?? this.chatrooms,
      isLoading: isLoading ?? this.isLoading,
      currentUserUuid: currentUserUuid ?? this.currentUserUuid,
      fetchedUsers: fetchedUsers ?? this.fetchedUsers,
    );
  }
}

class HomeScreenNotifier extends StateNotifier<HomeScreenState> {
  final Ref ref;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  HomeScreenNotifier(this.ref)
      : super(HomeScreenState(
          chatrooms: {},
          isLoading: true,
          currentUserUuid: '',
          fetchedUsers: [],
        )) {
    _initializeUserData().then((_) => _loadChatrooms());
  }

  Future<void> _initializeUserData() async {
    final authProvider = ref.read(authServiceProvider);
    final userId = await authProvider.getUid();
    state = state.copyWith(currentUserUuid: userId);
    // Initialize WebSocket connection
    // ref
    //     .read(webSocketServiceProvider)
    //     .connect('ws://chatterg-.leapcell.app/ws?userID=$userId');
  }

  Future<void> _loadChatrooms() async {
    try {
      ApiClient apiClient = ApiClient();
      // MongoDBDataSource mongoDBDataSource = MongoDBDataSource();
      final fetchedUsers = await apiClient.getUsers();
      final chatrooms = <String, List<dynamic>>{};
      for (var user in fetchedUsers) {
        chatrooms[user.name] = [];
      }
      state = state.copyWith(
        fetchedUsers: fetchedUsers,
        chatrooms: chatrooms,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      scaffoldKey.currentContext?.let((context) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e')),
        );
      });
    }
  }

  Future<void> refreshChatrooms() async {
    state = state.copyWith(isLoading: true);
    await _loadChatrooms();
  }

  Future<void> signOut(BuildContext context) async {
    await ref.read(authServiceProvider).signOut(context);
  }

  void dispose() {
    // ref.read(webSocketServiceProvider).dispose();
  }
}

// Extension to handle null context
extension ContextExtension on BuildContext? {
  void let(void Function(BuildContext) callback) {
    if (this != null) {
      callback(this!);
    }
  }
}

final homeScreenProvider =
    StateNotifierProvider<HomeScreenNotifier, HomeScreenState>((ref) {
  return HomeScreenNotifier(ref);
});

// Bottom Navigation Provider
final bottomNavProvider =
    StateProvider<int>((ref) => 1); // Start with ChatterG tab
