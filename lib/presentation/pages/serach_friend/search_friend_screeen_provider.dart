import 'package:chatterg/data/datasources/remote/api_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class SearchFriendScreenState {
  final List<AppUser> allUsers;
  final List<AppUser> filteredUsers;
  final List<AppUser> friends; // Add friends list to state
  final bool isLoading;
  final String currentUserUuid;
  final String searchQuery;
  final bool isSearching;
  final AppUser? selectedUser;
  final bool isSendingRequest;
  final bool isLoadingFriends; // Add loading state for friends

  SearchFriendScreenState({
    required this.allUsers,
    required this.filteredUsers,
    required this.friends,
    required this.isLoading,
    required this.currentUserUuid,
    required this.searchQuery,
    required this.isSearching,
    this.selectedUser,
    required this.isSendingRequest,
    required this.isLoadingFriends,
  });

  SearchFriendScreenState copyWith({
    List<AppUser>? allUsers,
    List<AppUser>? filteredUsers,
    List<AppUser>? friends,
    bool? isLoading,
    String? currentUserUuid,
    String? searchQuery,
    bool? isSearching,
    AppUser? selectedUser,
    bool? isSendingRequest,
    bool? isLoadingFriends,
  }) {
    return SearchFriendScreenState(
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      friends: friends ?? this.friends,
      isLoading: isLoading ?? this.isLoading,
      currentUserUuid: currentUserUuid ?? this.currentUserUuid,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      selectedUser: selectedUser ?? this.selectedUser,
      isSendingRequest: isSendingRequest ?? this.isSendingRequest,
      isLoadingFriends: isLoadingFriends ?? this.isLoadingFriends,
    );
  }
}

class SearchFriendScreenNotifier
    extends StateNotifier<SearchFriendScreenState> {
  final Ref ref;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  SearchFriendScreenNotifier(this.ref)
      : super(SearchFriendScreenState(
          allUsers: [],
          filteredUsers: [],
          friends: [],
          isLoading: true,
          currentUserUuid: '',
          searchQuery: '',
          isSearching: false,
          isSendingRequest: false,
          isLoadingFriends: false,
        )) {
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final authProvider = ref.read(authServiceProvider);
      final userId = await authProvider.getUid();

      state = state.copyWith(currentUserUuid: userId);

      // Load both users and friends concurrently
      await Future.wait([
        _loadUsers(),
        _loadFriends(),
      ]);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _showError('Failed to initialize: $e');
    }
  }

  Future<void> _loadUsers() async {
    try {
      state = state.copyWith(isLoading: true);

      ApiClient apiClient = ApiClient();
      final fetchedUsers = await apiClient.getUsers();

      // Filter out current user from the list
      final usersWithoutCurrentUser = fetchedUsers
          .where((user) => user.uuid != state.currentUserUuid)
          .toList();

      state = state.copyWith(
        allUsers: usersWithoutCurrentUser,
        isLoading: false,
      );

      // Apply filtering after users are loaded
      _applyFiltering();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _showError('Failed to load users: $e');
    }
  }

  Future<void> _loadFriends() async {
    try {
      state = state.copyWith(isLoadingFriends: true);

      ApiClient apiClient = ApiClient();
      final fetchedFriends =
          await apiClient.getFriends(userUuid: state.currentUserUuid);

      state = state.copyWith(
        friends: fetchedFriends,
        isLoadingFriends: false,
      );

      // Apply filtering after friends are loaded
      _applyFiltering();
    } catch (e) {
      state = state.copyWith(isLoadingFriends: false);
      _showError('Failed to load friends: $e');
    }
  }

  void _applyFiltering() {
    // Get friend UUIDs for easy comparison
    final friendUuids = state.friends.map((friend) => friend.uuid).toSet();

    // Filter out friends from all users
    final usersWithoutFriends = state.allUsers
        .where((user) => !friendUuids.contains(user.uuid))
        .toList();

    if (state.searchQuery.isEmpty) {
      state = state.copyWith(filteredUsers: usersWithoutFriends);
    } else {
      // Apply search filter to users without friends
      final searchFiltered = usersWithoutFriends
          .where((user) =>
              user.name
                  .toLowerCase()
                  .contains(state.searchQuery.toLowerCase()) ||
              user.username!
                  .toLowerCase()
                  .contains(state.searchQuery.toLowerCase()))
          .toList();

      state = state.copyWith(filteredUsers: searchFiltered);
    }
  }

  void searchUsers(String query) {
    state = state.copyWith(
      searchQuery: query,
      isSearching: query.isNotEmpty,
    );

    _applyFiltering();
  }

  Future<void> selectUser(AppUser user) async {
    try {
      // Get detailed user information
      ApiClient apiClient = ApiClient();
      final userDetails = await apiClient.getUserByUUID(uuid: user.uuid);
      final detailedUser = AppUser.fromJson(userDetails);

      state = state.copyWith(selectedUser: detailedUser);
    } catch (e) {
      _showError('Failed to load user details: $e');
    }
  }

  Future<void> sendFriendRequest(String receiver_uuid) async {
    try {
      state = state.copyWith(isSendingRequest: true);

      ApiClient apiClient = ApiClient();
      final result = await apiClient.sendFriendRequest(
        userUuid: state.currentUserUuid,
        receiverUuid: receiver_uuid,
      );
      print(result);

      state = state.copyWith(isSendingRequest: false);

      // Show success message
      scaffoldKey.currentContext?.let((context) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Friend request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      });

      // Optional: Remove the user from the filtered list after sending request
      // This prevents users from sending multiple requests to the same person
      final updatedFilteredUsers = state.filteredUsers
          .where((user) => user.uuid != receiver_uuid)
          .toList();

      state = state.copyWith(filteredUsers: updatedFilteredUsers);
    } catch (e) {
      state = state.copyWith(isSendingRequest: false);
      _showError('Failed to send friend request: $e');
    }
  }

  void clearSelectedUser() {
    state = state.copyWith(selectedUser: null);
  }

  Future<void> refreshUsers() async {
    // Reset loading states and reload both users and friends
    state = state.copyWith(
      isLoading: true,
      isLoadingFriends: true,
    );

    await Future.wait([
      _loadUsers(),
      _loadFriends(),
    ]);
  }

  void _showError(String message) {
    scaffoldKey.currentContext?.let((context) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    });
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

final searchFriendScreenProvider =
    StateNotifierProvider<SearchFriendScreenNotifier, SearchFriendScreenState>(
  (ref) => SearchFriendScreenNotifier(ref),
);
