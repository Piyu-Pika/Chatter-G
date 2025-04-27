import 'dart:convert';

import 'package:chatterg/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/datasources/remote/cockroachdb_data_source.dart';
import '../../providers/auth_provider.dart';
import '../login_page/login_page.dart'; // Renamed from signup_page.dart

final signupIsPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final signupIsConfirmPasswordVisibleProvider =
    StateProvider<bool>((ref) => false);
final termsAcceptedProvider = StateProvider<bool>((ref) => false);

class SignupPage extends ConsumerWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.79; // Adjusted height slightly

    // Listen for errors from AuthService
    ref.listen<String?>(
      authServiceProvider.select((value) => value.errorMessage),
      (_, errorMessage) {
        if (errorMessage != null && errorMessage.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
          // ref.read(authServiceProvider).clearError(); // Optional: clear error
        }
      },
    ); // Slightly taller for more fields

    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: context.backgroundGradient,
        ),
        child: Stack(
          children: [
            // App Logo in the upper portion
            Positioned(
              top: screenHeight * 0.06,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      "assets/images/chatter-g.jpg",
                      width: 100,
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign up to get started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Fixed Bottom Sheet for Signup Form
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomSheetHeight,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: const SignupForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ... SignupForm class ...
class SignupForm extends ConsumerStatefulWidget {
  const SignupForm({super.key});

  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  // Use TextEditingControllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch necessary states from providers
    final isPasswordVisible = ref.watch(signupIsPasswordVisibleProvider);
    final isConfirmPasswordVisible =
        ref.watch(signupIsConfirmPasswordVisibleProvider);
    final termsAccepted = ref.watch(termsAcceptedProvider);
    final authService = ref.watch(authServiceProvider); // Watch the service
    final isLoading = authService.isLoading; // Get loading state

    void handleSignup() async {
      // Validate form first (optional but recommended)
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fix the errors above')),
        );
        return;
      }

      // Check if terms are accepted
      if (!termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must accept the Terms and Conditions')),
        );
        return;
      }

      // Get values from controllers
      _nameController.text.trim(); // Get name
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim(); // Get name
      // Confirm password validation is handled by the TextFormField validator now

      // Call the register method from AuthService
      // Note: Firebase Auth doesn't store the name directly during creation.
      // You usually save it to Firestore/RTDB linked by the user's UID after successful registration.
      // We'll pass email and password here. You might need another step post-registration
      // to save the user's name in your database.
      await ref
          .read(authServiceProvider)
          .registerWithEmailPassword(name, email, password)
          .then((value) {
        CockroachDBDataSource().saveData({
          'uuid': authService.currentUser?.uid,
          'name': name,
          'email': email,
          'username': email.split('@')[0],
          'bio': 'Hey there! I am using Chatter G.',
        });
      });

      // No navigation or success message here - AuthWrapper handles navigation
      // Error display is handled by the listener in SignupPage build method
    }

    void handleGoogleSignIn() async {
      await ref.read(authServiceProvider).signInWithGoogle(context);
      // Navigation and error handling are managed elsewhere
    }

    return SingleChildScrollView(
      // Wrap form content
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          // Wrap with Form widget
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle and Title
              Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: appTheme.textTheme.titleLarge!.color,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon:
                      Icon(Icons.person_outline, color: Colors.green[700]),
                  // ... border styles ...
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: appTheme.colorScheme.outline, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
              ),

              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  // Basic email validation
                  final emailRegExp =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegExp.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  prefixIcon:
                      Icon(Icons.email_outlined, color: Colors.green[700]),
                  // ... border styles ...
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: appTheme.colorScheme.outline, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Create a password (min. 6 characters)',
                  prefixIcon:
                      Icon(Icons.lock_outline, color: Colors.green[700]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => ref
                        .read(signupIsPasswordVisibleProvider.notifier)
                        .state = !isPasswordVisible,
                  ),
                  // ... border styles ...
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: appTheme.colorScheme.outline, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                obscureText: !isConfirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Confirm your password',
                  prefixIcon:
                      Icon(Icons.lock_outline, color: Colors.green[700]),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isConfirmPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => ref
                        .read(signupIsConfirmPasswordVisibleProvider.notifier)
                        .state = !isConfirmPasswordVisible,
                  ),
                  // ... border styles ...
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: appTheme.colorScheme.outline, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Terms and Conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start, // Align items top
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: termsAccepted,
                      activeColor: Colors.green[700],
                      onChanged: (value) {
                        // Update the state provider for the checkbox
                        ref.read(termsAcceptedProvider.notifier).state =
                            value ?? false;
                      },
                      visualDensity:
                          VisualDensity.compact, // Make checkbox smaller
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap, // Reduce tap area
                    ),
                  ),
                  const SizedBox(width: 8), // Reduced space
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 4.0), // Align text better
                      child: RichText(
                        // Use RichText for tappable links
                        text: TextSpan(
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 12),
                          children: [
                            const TextSpan(
                                text: 'By signing up, you agree to our '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                  color: Colors.green[700],
                                  decoration: TextDecoration.underline),
                              // recognizer: TapGestureRecognizer()..onTap = () { /* TODO: Open Terms URL */ }
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                  color: Colors.green[700],
                                  decoration: TextDecoration.underline),
                              // recognizer: TapGestureRecognizer()..onTap = () { /* TODO: Open Privacy URL */ }
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Signup Button
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : handleSignup, // Use isLoading from authService
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme
                      .elevatedButtonTheme.style!.backgroundColor
                      ?.resolve({}), // Resolve MaterialStateProperty to Color
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.green[200],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: isLoading // Use isLoading from authService
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'CREATE ACCOUNT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),

              const SizedBox(height: 15),

              // Login Option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?',
                      style: TextStyle(color: Colors.grey[600])),
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            // Disable if loading
                            // Navigate back to Login Page
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()));
                          },
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: appTheme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // Social Signup Options
              Column(
                children: [
                  Text(
                    'Or sign up with',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _socialSignupButton(Icons.g_mobiledata, 'Google',
                          handleGoogleSignIn, isLoading),
                      const SizedBox(width: 16),
                      _socialSignupButton(Icons.facebook, 'Facebook', () {},
                          isLoading), // Pass isLoading
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30), // Extra space at bottom for scrolling
            ],
          ),
        ),
      ),
    );
  }

  // Reusing the social button structure (can be extracted to a common widgets file)
  Widget _socialSignupButton(
      IconData icon, String provider, VoidCallback onPressed, bool isLoading) {
    return Expanded(
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed, // Disable when loading
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            isLoading // Show indicator inside button if needed during social auth
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 24, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(provider, style: TextStyle(color: Colors.grey[800])),
                    ],
                  ),
      ),
    );
  }
}
