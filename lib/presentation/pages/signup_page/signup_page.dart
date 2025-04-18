import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home_screen/home_screen.dart';
import '../login_page/login_page.dart'; // Renamed from signup_page.dart

// Providers for signup form
final signupNameProvider = StateProvider<String>((ref) => '');
final signupEmailProvider = StateProvider<String>((ref) => '');
final signupPasswordProvider = StateProvider<String>((ref) => '');
final signupConfirmPasswordProvider = StateProvider<String>((ref) => '');
final signupIsPasswordVisibleProvider = StateProvider<bool>((ref) => false);
final signupIsConfirmPasswordVisibleProvider =
    StateProvider<bool>((ref) => false);
final signupIsLoadingProvider = StateProvider<bool>((ref) => false);

class SignupPage extends ConsumerWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight =
        screenHeight * 0.70; // Slightly taller for more fields

    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green[900]!, // Dark Green
              Colors.green[600]!, // Lighter Green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // App Logo in the upper portion
            Positioned(
              top: screenHeight * 0.08,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      "assets/images/godzilla.png",
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

class SignupForm extends ConsumerWidget {
  const SignupForm({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(signupNameProvider);
    final email = ref.watch(signupEmailProvider);
    final password = ref.watch(signupPasswordProvider);
    final confirmPassword = ref.watch(signupConfirmPasswordProvider);
    final isPasswordVisible = ref.watch(signupIsPasswordVisibleProvider);
    final isConfirmPasswordVisible =
        ref.watch(signupIsConfirmPasswordVisibleProvider);
    final isLoading = ref.watch(signupIsLoadingProvider);

    void handleSignup() async {
      // Validate form fields
      if (name.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          confirmPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      // Basic email validation
      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid email address')),
        );
        return;
      }

      // Set loading state
      ref.read(signupIsLoadingProvider.notifier).state = true;

      // Simulate API call for registration
      await Future.delayed(const Duration(seconds: 2));

      // Reset loading state
      ref.read(signupIsLoadingProvider.notifier).state = false;

      // Navigate to home screen after successful signup
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                    color: Colors.green[900],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Full Name Field
            TextField(
              onChanged: (value) =>
                  ref.read(signupNameProvider.notifier).state = value,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon:
                    Icon(Icons.person_outline, color: Colors.green[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              keyboardType: TextInputType.name,
            ),

            const SizedBox(height: 16),

            // Email Field
            TextField(
              onChanged: (value) =>
                  ref.read(signupEmailProvider.notifier).state = value,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email address',
                prefixIcon:
                    Icon(Icons.email_outlined, color: Colors.green[700]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[700]!, width: 2),
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
            TextField(
              onChanged: (value) =>
                  ref.read(signupPasswordProvider.notifier).state = value,
              obscureText: !isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Create a password',
                prefixIcon: Icon(Icons.lock_outline, color: Colors.green[700]),
                suffixIcon: IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[600],
                  ),
                  onPressed: () => ref
                      .read(signupIsPasswordVisibleProvider.notifier)
                      .state = !isPasswordVisible,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Confirm Password Field
            TextField(
              onChanged: (value) => ref
                  .read(signupConfirmPasswordProvider.notifier)
                  .state = value,
              obscureText: !isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm your password',
                prefixIcon: Icon(Icons.lock_outline, color: Colors.green[700]),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[700]!, width: 2),
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
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: true, // You can create a provider for this
                    activeColor: Colors.green[700],
                    onChanged: (value) {
                      // Handle checkbox change
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'By signing up, you agree to our Terms of Service and Privacy Policy',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Signup Button
            ElevatedButton(
              onPressed: isLoading ? null : handleSignup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.green[200],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: isLoading
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

            const SizedBox(height: 20),

            // Login Option
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account?',
                    style: TextStyle(color: Colors.grey[600])),
                TextButton(
                  onPressed: () {
                    // Navigate to login page
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                  },
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

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
                    _socialSignupButton(Icons.g_mobiledata, 'Google'),
                    const SizedBox(width: 16),
                    _socialSignupButton(Icons.facebook, 'Facebook'),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20), // Extra space at bottom for scrolling
          ],
        ),
      ),
    );
  }

  Widget _socialSignupButton(IconData icon, String provider) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(provider),
          ],
        ),
      ),
    );
  }
}
