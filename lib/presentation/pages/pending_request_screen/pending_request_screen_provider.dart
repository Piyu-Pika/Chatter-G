// improved_pending_request_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatterg/data/models/user_model.dart';

import '../../../data/datasources/remote/api_value.dart';

// Enhanced state with better granularity
class PendingRequestState {
  final List<Map<String, dynamic>> pendingRequests;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final List<Map<String, dynamic>> blockedUsers;
  final Set<String> processingRequests; // Track individual request processing
  final DateTime? lastUpdated;
  final bool hasReachedMax;

  const PendingRequestState({
    this.pendingRequests = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.blockedUsers = const [],
    this.processingRequests = const {},
    this.lastUpdated,
    this.hasReachedMax = false,
  });

  PendingRequestState copyWith({
    List<Map<String, dynamic>>? pendingRequests,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    List<Map<String, dynamic>>? blockedUsers,
    Set<String>? processingRequests,
    DateTime? lastUpdated,
    bool? hasReachedMax,
  }) {
    return PendingRequestState(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      processingRequests: processingRequests ?? this.processingRequests,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  bool isRequestProcessing(String requestId) => processingRequests.contains(requestId);
}

class PendingRequestNotifier extends StateNotifier<PendingRequestState> {
  final ApiClient _apiClient;
  final Ref _ref;

  PendingRequestNotifier(this._apiClient, this._ref) : super(const PendingRequestState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      loadPendingRequests(),
      loadBlockedUsers(),
    ]);
  }

  Future<void> loadPendingRequests({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _apiClient.getFriendRequests(type: 'received');
      final requests = (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      
      state = state.copyWith(
        pendingRequests: requests,
        isLoading: false,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
        hasReachedMax: requests.length < 20, // Assuming 20 is page size
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: _formatError(e),
      );
    }
  }

  Future<void> loadBlockedUsers() async {
    try {
      final blockedUsers = await _apiClient.getBlockedUsers();
      state = state.copyWith(blockedUsers: blockedUsers.cast<Map<String, dynamic>>());
    } catch (e) {
      debugPrint('Error loading blocked users: $e');
    }
  }

  Future<void> respondToRequest(String requestId, String action) async {
    // Add optimistic update
    final requestIndex = state.pendingRequests.indexWhere((r) => r['id'] == requestId);
    if (requestIndex == -1) return;

    // Mark request as processing
    final updatedProcessing = Set<String>.from(state.processingRequests)..add(requestId);
    state = state.copyWith(processingRequests: updatedProcessing);

    try {
      await _apiClient.respondToFriendRequest(requestId: requestId, action: action);
      
      // Remove request on success
      final updatedRequests = List<Map<String, dynamic>>.from(state.pendingRequests)
        ..removeWhere((request) => request['id'] == requestId);
      
      final updatedProcessingFinal = Set<String>.from(state.processingRequests)..remove(requestId);
      
      state = state.copyWith(
        pendingRequests: updatedRequests,
        processingRequests: updatedProcessingFinal,
      );

      // Show success feedback
      _showSuccessMessage(action == 'accept' ? 'Friend request accepted' : 'Friend request rejected');
      
    } catch (e) {
      // Remove processing state and show error
      final updatedProcessingError = Set<String>.from(state.processingRequests)..remove(requestId);
      state = state.copyWith(
        processingRequests: updatedProcessingError,
        error: _formatError(e),
      );
    }
  }

  Future<void> blockUser(String user_uuid) async {
    try {
      await _apiClient.blockUser(user_uuid: user_uuid);
      
      // Remove any pending request from this user
      final updatedRequests = state.pendingRequests
          .where((request) => request['sender']['user_uuid'] != user_uuid)
          .toList();
      
      state = state.copyWith(pendingRequests: updatedRequests);
      
      // Reload blocked users
      await loadBlockedUsers();
      _showSuccessMessage('User blocked successfully');
      
    } catch (e) {
      state = state.copyWith(error: _formatError(e));
    }
  }

  Future<void> unblockUser(String user_uuid) async {
    try {
      await _apiClient.unblockUser(user_uuid: user_uuid);
      await loadBlockedUsers();
      _showSuccessMessage('User unblocked successfully');
    } catch (e) {
      state = state.copyWith(error: _formatError(e));
    }
  }

  bool isUserBlocked(String user_uuid) {
    return state.blockedUsers.any((user) => user['user_uuid'] == user_uuid);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  String _formatError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return error.toString();
  }

  void _showSuccessMessage(String message) {
    // This could be enhanced with a proper notification system
    debugPrint('Success: $message');
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Provider definition
final pendingRequestProvider = StateNotifierProvider<PendingRequestNotifier, PendingRequestState>(
  (ref) => PendingRequestNotifier(ref.read(apiClientProvider), ref),
);

// Assuming you have an API client provider
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
