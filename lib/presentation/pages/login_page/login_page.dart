import 'package:flutter/material.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Welcome'),
          backgroundColor: Colors.green[900], // Match gradient start color
          elevation: 0, // Remove app bar shadow
        ),
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
          child: Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.green[900],
                backgroundColor: Colors.white, // Text color
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Login'),
              onPressed: () => _showLoginSheet(context),
            ),
          ),
        ));
  }

  // Method to show the bottom sheet covering 60% of the screen
  void _showLoginSheet(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Important for content to resize with keyboard and setting height
      backgroundColor: Colors.transparent, // Make modal background transparent
      builder: (BuildContext bc) {
        return Container(
          height: screenHeight * 0.6, // Set height to 60% of screen height
          decoration: const BoxDecoration(
            color: Colors.white, // Set background color for the sheet content
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25.0),
              topRight: Radius.circular(25.0),
            ),
          ),
          child: Padding(
            // Add padding inside the sheet, adjust for keyboard
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24.0,
              right: 24.0,
              top: 24.0,
            ),
            child: SingleChildScrollView(
              // Allows scrolling if keyboard reduces space
              child: Column(
                mainAxisSize: MainAxisSize.min, // Take minimum space needed
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Login',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Username or Email',
                      hintText: 'Enter your username or email',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.green[700]!),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.green[700]!),
                      ),
                      // Consider adding a suffix icon to toggle password visibility
                    ),
                    obscureText: true, // Hides password input
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Add your login logic here
                      Navigator.pop(context); // Close the bottom sheet
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.green[700], // Button background color
                      foregroundColor: Colors.white, // Button text color
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    child: const Text('Sign In'),
                  ),
                  const SizedBox(
                      height:
                          20), // Add some space at the bottom inside scroll view
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
