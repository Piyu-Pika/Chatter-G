import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async'; // Required for StreamSubscription

// Provider for FirebaseAuth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Provider for GoogleSignIn instance
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

// Auth state changes stream provider
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Main Auth Provider
final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService(
      ref.watch(firebaseAuthProvider), ref.watch(googleSignInProvider));
});

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  StreamSubscription? _authStateSubscription;

  User? _user;
  User? get currentUser => _user;
  String? get uid => _user?.uid;
  bool get isLoggedIn => _user != null;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthService(this._firebaseAuth, this._googleSignIn) {
    // Listen to auth state changes immediately
    _authStateSubscription =
        _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
    _user = _firebaseAuth
        .currentUser; // Initialize with current user if already logged in
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _setError(String message) {
    _errorMessage = message;
    _setLoading(false); // Ensure loading is stopped on error
    notifyListeners();
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    _isLoading = false; // Stop loading when auth state changes
    _clearError(); // Clear any previous errors on successful auth change
    notifyListeners();
  }

  Future<void> registerWithEmailPassword(String email, String password) async {
    _clearError();
    _setLoading(true);
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Auth state listener will handle the update
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Registration failed');
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      // Loading state is handled by _onAuthStateChanged or _setError
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    _clearError();
    _setLoading(true);
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Auth state listener will handle the update
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Login failed');
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    } finally {
      // Loading state is handled by _onAuthStateChanged or _setError
    }
  }

  Future<void> signInWithGoogle() async {
    _clearError();
    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        _setLoading(false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
      // Auth state listener will handle the update
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Google Sign-In failed');
    } catch (e) {
      _setError(
          'An unexpected error occurred during Google Sign-In: ${e.toString()}');
    } finally {
      // Loading state is handled by _onAuthStateChanged or _setError
    }
  }

  Future<void> signOut() async {
    _clearError();
    _setLoading(true);
    try {
      // It's good practice to sign out from GoogleSignIn as well
      // if the user signed in with Google. Check if the provider is Google.
      if (_user?.providerData.any((userInfo) =>
              userInfo.providerId == GoogleAuthProvider.PROVIDER_ID) ??
          false) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      // Auth state listener will handle the update
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Sign out failed');
    } catch (e) {
      _setError(
          'An unexpected error occurred during sign out: ${e.toString()}');
    } finally {
      // Loading state is handled by _onAuthStateChanged or _setError
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }
}

// Example Usage (Optional, shows how to use the provider)
class AuthScreen extends ConsumerWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Firebase Auth Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: authState.when(
            data: (user) {
              if (authService.isLoading) {
                return CircularProgressIndicator();
              }
              if (user != null) {
                // User is logged in
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Welcome!'),
                    Text('Email: ${user.email ?? 'N/A'}'),
                    Text('UID: ${user.uid}'),
                    SizedBox(height: 20),
                    if (authService.errorMessage != null)
                      Text('Error: ${authService.errorMessage}',
                          style: TextStyle(color: Colors.red)),
                    ElevatedButton(
                      onPressed: () => ref.read(authServiceProvider).signOut(),
                      child: Text('Sign Out'),
                    ),
                  ],
                );
              } else {
                // User is logged out
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (authService.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text('Error: ${authService.errorMessage}',
                            style: TextStyle(color: Colors.red)),
                      ),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    SizedBox(height: 20),
                    if (authService.isLoading)
                      CircularProgressIndicator()
                    else ...[
                      ElevatedButton(
                        onPressed: () {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();
                          if (email.isNotEmpty && password.isNotEmpty) {
                            ref
                                .read(authServiceProvider)
                                .signInWithEmailPassword(email, password);
                          }
                        },
                        child: Text('Sign In with Email'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          final email = _emailController.text.trim();
                          final password = _passwordController.text.trim();
                          if (email.isNotEmpty && password.isNotEmpty) {
                            ref
                                .read(authServiceProvider)
                                .registerWithEmailPassword(email, password);
                          }
                        },
                        child: Text('Register with Email'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(authServiceProvider).signInWithGoogle(),
                        child: Text('Sign In with Google'),
                      ),
                    ],
                  ],
                );
              }
            },
            loading: () => CircularProgressIndicator(),
            error: (error, stack) => Text('Auth Stream Error: $error'),
          ),
        ),
      ),
    );
  }
}
