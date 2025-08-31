import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
// import 'package:chatterg/data/models/user_model.dart' as AppUser;

// import '../../data/datasources/remote/api_value.dart';
import '../../data/datasources/remote/api_value.dart';
import '../../data/datasources/remote/notification_service.dart';
import '../../data/models/user_model.dart';
import '../pages/home_screen/home_screen.dart'; // Required for StreamSubscription
import 'package:dev_log/dev_log.dart';


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
  // This stream provider is useful for reacting to auth state changes
  // in the UI layer (e.g., redirecting in main.dart or a wrapper widget),
  // which is generally the recommended approach for navigation.
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Main Auth Provider
final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService(
      ref.watch(firebaseAuthProvider), ref.watch(googleSignInProvider));
});

class AuthService extends ChangeNotifier {
  // final cockroachDBDataSource = MongoDBDataSource();
  // final ApiClient _apiClient = ApiClient();
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  // final Ref _ref; // Store Ref to potentially read other providers if needed
  StreamSubscription? _authStateSubscription;
  final Map<String, dynamic> data = Map<String, dynamic>.from({
    'name': '',
    'email': '',
    'uuid': '',
    'createdAt': '',
    'updatedAt': '',
  });

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
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      // Optionally notify listeners if UI reacts to error clearing
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    _setLoading(false); // Ensure loading is stopped on error
    notifyListeners();
  }

  Future<void> _initializeNotifications(User firebaseUser) async {
    try {
      final uuid = firebaseUser.uid;
      final userModel = await ApiClient().getUserByUUID(uuid: uuid);
      final user = AppUser.fromJson(userModel);
      final token = await firebaseUser.getIdToken();

      // Use full initialization with AppUser for complete setup
      await NotificationService.initialize(user, authToken: token ?? '');
      L.i('Notifications initialized and FCM token sent to server');
    } catch (e) {
      L.e('Failed to initialize notifications: $e');
      // Fallback to basic initialization to at least send FCM token
      await NotificationService.initializeBasic();
    }
  }

  // This listener updates the internal state and notifies listeners.
  // UI reacting to authServiceProvider or authStateChangesProvider
  // can handle navigation based on these state changes.
  void _onAuthStateChanged(User? user) {
    _user = user;
    _isLoading = false; // Stop loading when auth state changes
    _clearError(); // Clear any previous errors on successful auth change
    notifyListeners();
  }

  //getting uid of the current user
  Future<String> getUid() async {
    L.i('Getting UID of the current user...${_firebaseAuth.currentUser}');
    return _firebaseAuth.currentUser!.uid;
  }

  Future<void> registerWithEmailPassword(
      String name, String email, String password) async {
    _clearError();
    _setLoading(true);
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Sign-up success triggers the authStateChanges stream.
      // The _onAuthStateChanged listener will update the state.
      // Navigation should ideally be handled by the UI listening to auth state.
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Registration failed');
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    }
    // No finally _setLoading(false) needed here if relying on _onAuthStateChanged or _setError
  }

  // Modified to include BuildContext for navigation
  Future<void> signInWithEmailPassword(
      BuildContext context, String email, String password) async {
    _clearError();
    _setLoading(true);
    try {
      await _firebaseAuth
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      )
       ;
      // Sign-in success triggers the authStateChanges stream.
      // The _onAuthStateChanged listener will update the state.

      // Direct navigation after successful sign-in:
      // Note: It's generally preferred to handle navigation in the UI layer
      // by listening to auth state changes (e.g., using authStateChangesProvider).
      // This keeps the service layer decoupled from the UI.
      if (_firebaseAuth.currentUser != null && context.mounted) {
        await _initializeNotifications(_firebaseAuth.currentUser!);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          // Remove all previous routes
        );
      } else {
        // If user is null after await or context is unmounted, handle error state
        _setLoading(
            false); // Manually set loading false if navigation doesn't happen
      }
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Login failed');
    } catch (e) {
      _setError('An unexpected error occurred: ${e.toString()}');
    }
    // No finally _setLoading(false) needed here if relying on _onAuthStateChanged,
    // _setError, or successful navigation path.
  }

  // Modified to include BuildContext for navigation
  Future<void> signInWithGoogle(BuildContext context) async {
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
      // Sign-in success triggers the authStateChanges stream.
      // The _onAuthStateChanged listener will update the state.

      // Direct navigation after successful sign-in:
      // Note: It's generally preferred to handle navigation in the UI layer
      // by listening to auth state changes (e.g., using authStateChangesProvider).
      if (_firebaseAuth.currentUser != null && context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      } else {
        // If user is null after await or context is unmounted, handle error state
        _setLoading(
            false); // Manually set loading false if navigation doesn't happen
      }
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Google Sign-In failed');
    } catch (e) {
      _setError(
          'An unexpected error occurred during Google Sign-In: ${e.toString()}');
    }
    // No finally _setLoading(false) needed here if relying on _onAuthStateChanged,
    // _setError, or successful navigation path.
  }

  // Import necessary for Facebook Auth
  // facebook sign in method

  //Forgot password method
  Future<void> forgotPassword(String email) async {
    _clearError();
    _setLoading(true);
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      // Sign-out success triggers the authStateChanges stream.
      // The _onAuthStateChanged listener will update the state.
      // Navigation (e.g., back to login screen) should be handled in the UI layer
      // listening to the auth state.
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Forgot password failed');
    } catch (e) {
      _setError(
          'An unexpected error occurred during forgot password: ${e.toString()}');
    }
    // No finally _setLoading(false) needed here if relying on _onAuthStateChanged,
    // _setError, successful navigation path, or manual _setLoading(false) in cancel case.
  }

  Future<void> signOut(context) async {
    _clearError();
    // Don't necessarily need to set loading true for sign out unless there's UI feedback
    // _setLoading(true);
    try {
      // Check if the user signed in with Google to sign out from there too.
      final isGoogleUser = _user?.providerData.any(
              (info) => info.providerId == GoogleAuthProvider.PROVIDER_ID) ??
          false;
      if (isGoogleUser) {
        // Condition ensures we only call Google SignOut if it was used.
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
      Navigator.popUntil(context, (route) => route.isFirst);
      // Sign-out success triggers the authStateChanges stream.
      // The _onAuthStateChanged listener will update the state.
      // Navigation (e.g., back to login screen) should be handled in the UI layer
      // listening to the auth state.
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Sign out failed');
    } catch (e) {
      _setError(
          'An unexpected error occurred during sign out: ${e.toString()}');
    }
    // _setLoading handled by _onAuthStateChanged or _setError
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel(); // Cancel the subscription
    super.dispose();
  }
}
