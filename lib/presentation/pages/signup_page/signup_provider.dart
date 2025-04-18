import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';

// State for the Auth provider
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  // Method to register a new user
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Set loading state
      state = state.copyWith(isLoading: true, error: null);

      // In a real app, you would make an API call to your backend
      // For demonstration, we'll simulate a network delay
      await Future.delayed(const Duration(seconds: 2));

      // Create a mock user
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Update state with the new user
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      // Handle error
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to register: ${e.toString()}',
      );
    }
  }

  // Method to log in an existing user
  Future<void> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Set loading state
      state = state.copyWith(isLoading: true, error: null);

      // In a real app, you would make an API call to your backend
      await Future.delayed(const Duration(seconds: 2));

      // Create a mock user for demonstration
      final user = User(
        id: 'mock-user-id',
        name: 'Test User',
        email: email,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Update state with the logged in user
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      // Handle error
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to login: ${e.toString()}',
      );
    }
  }

  // Method to log out the current user
  void logoutUser() {
    state = AuthState();
  }
}

// Create the provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user != null;
});
