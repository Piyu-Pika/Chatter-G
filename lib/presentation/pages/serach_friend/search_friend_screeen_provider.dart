import 'package:chatterg/data/datasources/remote/api_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user_model.dart';
import '../../providers/auth_provider.dart';

class SearchFriendScreenState {
  final List<AppUser> allUsers;
  final List<AppUser> filteredUsers;
  final bool isLoading;
  final String currentUserUuid;
  final String searchQuery;
  final bool isSearching;
  final AppUser? selectedUser;
  final bool isSendingRequest;

  SearchFriendScreenState({
    required this.allUsers,
    required this.filteredUsers,
    required this.isLoading,
    required this.currentUserUuid,
    required this.searchQuery,
    required this.isSearching,
    this.selectedUser,
    required this.isSendingRequest,
  });

  SearchFriendScreenState copyWith({
    List<AppUser>? allUsers,
    List<AppUser>? filteredUsers,
    bool? isLoading,
    String? currentUserUuid,
    String? searchQuery,
    bool? isSearching,
    AppUser? selectedUser,
    bool? isSendingRequest,
  }) {
    return SearchFriendScreenState(
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      isLoading: isLoading ?? this.isLoading,
      currentUserUuid: currentUserUuid ?? this.currentUserUuid,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      selectedUser: selectedUser ?? this.selectedUser,
      isSendingRequest: isSendingRequest ?? this.isSendingRequest,
    );
  }
}

class SearchFriendScreenNotifier extends StateNotifier<SearchFriendScreenState> {
  final Ref ref;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  SearchFriendScreenNotifier(this.ref)
      : super(SearchFriendScreenState(
          allUsers: [],
          filteredUsers: [],
          isLoading: true,
          currentUserUuid: '',
          searchQuery: '',
          isSearching: false,
          isSendingRequest: false,
        )) {
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final authProvider = ref.read(authServiceProvider);
      final userId = await authProvider.getUid();
      
      state = state.copyWith(currentUserUuid: userId);
      await _loadUsers();
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
      final filteredUsers = fetchedUsers
          .where((user) => user.uuid != state.currentUserUuid)
          .toList();

      state = state.copyWith(
        allUsers: filteredUsers,
        filteredUsers: filteredUsers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      _showError('Failed to load users: $e');
    }
  }

  void searchUsers(String query) {
    state = state.copyWith(
      searchQuery: query,
      isSearching: query.isNotEmpty,
    );

    if (query.isEmpty) {
      state = state.copyWith(filteredUsers: state.allUsers);
    } else {
      final filtered = state.allUsers
          .where((user) =>
              user.name.toLowerCase().contains(query.toLowerCase()) ||
              user.username!.toLowerCase().contains(query.toLowerCase()))
          .toList();
      
      state = state.copyWith(filteredUsers: filtered);
    }
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
        receiver_uuid: receiver_uuid,
      );
      
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
      
    } catch (e) {
      state = state.copyWith(isSendingRequest: false);
      _showError('Failed to send friend request: $e');
    }
  }

  void clearSelectedUser() {
    state = state.copyWith(selectedUser: null);
  }

  Future<void> refreshUsers() async {
    await _loadUsers();
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
