import 'package:chatterg/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../signup_page/signup_page.dart';

final isPasswordVisibleProvider = StateProvider<bool>((ref) => false);

class LoginPage extends ConsumerWidget {
  LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.67;

    // Listen for errors from AuthService and show SnackBar
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
          // Optionally clear the error after showing it
          // ref.read(authServiceProvider).clearError();
        }
      },
    );

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
              top: screenHeight * 0.10,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      "assets/images/chatterg3.png",
                      width: 100,
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black.withAlpha(128),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Fixed Bottom Sheet for Login Form
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
                child: LoginForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Optional: for form validation

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the necessary states from providers
    final isPasswordVisible = ref.watch(isPasswordVisibleProvider);
    final authService =
        ref.watch(authServiceProvider); // Watch the service itself
    final isLoading = authService.isLoading; // Get loading state

    // ... handleLogin and handleGoogleSignIn methods ...
    void handleLogin() async {
      // Optional: Validate form
      if (!_formKey.currentState!.validate()) {
        return;
      }
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      // Call the login method from AuthService
      await ref
          .read(authServiceProvider)
          .signInWithEmailPassword(context, email, password);

      //get the user data from the database
      // _cockroachDBDataSource.getData().then((value) {
      //   // Handle success if needed
      //   print(value);
      // }).catchError((error) {
      //   // Handle error if needed
      //   print(error);
      // });

      // No navigation here - AuthWrapper handles it based on state change
      // No manual loading state management here - AuthService handles it
      // Error display is handled by the listener in LoginPage build method
    }

    void handleGoogleSignIn() async {
      await ref.read(authServiceProvider).signInWithGoogle(context);
      // Navigation and error handling are managed by AuthWrapper and the listener
    }

    void handleForgotPassword() async {
      await ref.read(authServiceProvider).forgotPassword(_emailController.text);

      // Navigation and error handling are managed by AuthWrapper and the listener
      SnackBar snackBar = SnackBar(
        content: Text('Password reset email sent'),
        backgroundColor: appTheme.snackBarTheme.backgroundColor,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        // Optional: Wrap with Form
        key: _formKey,
        child: SingleChildScrollView(
          // Added SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    'Sign In',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: appTheme.textTheme.titleLarge!.color,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Email Field
              TextFormField(
                // Use TextFormField for validation
                controller: _emailController,
                // validator: (value) { // Example validation
                //   if (value == null || value.isEmpty || !value.contains('@')) {
                //     return 'Please enter a valid email';
                //   }
                //   return null;
                // },
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: appTheme.iconTheme.color),
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

              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                // Use TextFormField
                controller: _passwordController,
                // validator: (value) { // Example validation
                //   if (value == null || value.isEmpty || value.length < 6) {
                //     return 'Password must be at least 6 characters';
                //   }
                //   return null;
                // },
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon:
                      Icon(Icons.lock_outline, color: appTheme.iconTheme.color),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => ref
                        .read(isPasswordVisibleProvider.notifier)
                        .state = !isPasswordVisible,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: appTheme.colorScheme.outline, width: 2)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
              ),

              // Forgot Password Link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    handleForgotPassword();
                    // Optionally navigate to a Forgot Password page
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: appTheme.colorScheme.primary),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Login Button
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : handleLogin, // Use isLoading from authService
                style: ElevatedButton.styleFrom(
                  backgroundColor: appTheme
                      .elevatedButtonTheme.style?.backgroundColor
                      ?.resolve({}),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: appTheme.disabledColor,
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
                        'SIGN IN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Sign Up Option
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Don\'t have an account?',
                      style: TextStyle(color: Colors.grey[600])),
                  TextButton(
                    onPressed: () {
                      // Navigate to Signup Page
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignupPage()));
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: appTheme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Social Login Options
              Column(
                children: [
                  Text(
                    'Or continue with',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Updated Google Button
                      _socialLoginButton(Icons.g_mobiledata, 'Google',
                          handleGoogleSignIn, isLoading),
                      const SizedBox(width: 16),
                      // Facebook Button (Placeholder)
                      _socialLoginButton(Icons.facebook, 'Facebook', () {},
                          isLoading), // Pass isLoading
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20), // Extra space at bottom for scrolling
            ],
          ),
        ),
      ),
    );
  }

  // Update _socialLoginButton to accept onPressed callback and loading state
  Widget _socialLoginButton(
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
                      Icon(icon,
                          size: 24,
                          color:
                              Colors.grey[700]), // Adjust icon color if needed
                      const SizedBox(width: 8),
                      Text(provider,
                          style: TextStyle(
                              color: Colors.grey[800])), // Adjust text color
                    ],
                  ),
      ),
    );
  }
}
