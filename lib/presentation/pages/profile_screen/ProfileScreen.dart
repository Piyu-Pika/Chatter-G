import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart' as AppUser;
import '../../providers/auth_provider.dart';
import '../../../data/datasources/remote/cockroachdb_data_source.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  User? _currentUser;
  late Future<String> _userDataFuture = Future.value('');

  // Hardcoded test data - you can remove this once the API is working correctly
  final String testData = '''
    {
      "uuid": "162BgS74dhM1Rm9KQHQ4oXbdCoz1",
      "name": "John Doe",
      "email": "test1@gmail.com",
      "created_at": "0001-01-01T00:00:00Z",
      "updated_at": "0001-01-01T00:00:00Z",
      "deleted_at": "0001-01-01T00:00:00Z",
      "username": "user123",
      "bio": "This is a test user account",
      "date_of_birth": "1990-01-01T00:00:00Z",
      "gender": "male",
      "phone_number": "+1234567890"
    }
  ''';

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await FirebaseAuth.instance.authStateChanges().first;
    setState(() {
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        // For testing, use the hardcoded data
        // Comment this line and uncomment the next one when API is working
        _userDataFuture = Future.value(testData);
        // _userDataFuture = CockroachDBDataSource().getData(_currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: FutureBuilder<String>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            print("Raw API data: $data"); // Debug print

            late AppUser.User user;
            try {
              user = parseUserData(data);
            } catch (e) {
              print("Parse error details: $e"); // Debug print
              return Center(
                child: Text(
                  'Error parsing user data: $e',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProfileItem('Name', user.name),
                  _buildProfileItem('Email', user.email),
                  _buildProfileItem('Username', user.username),
                  _buildProfileItem('Bio', user.bio),
                  _buildProfileItem(
                      'Date of Birth', _formatDate(user.dateOfBirth)),
                  _buildProfileItem('Gender', _capitalizeFirst(user.gender)),
                  _buildProfileItem('Phone Number', user.phoneNumber),
                  const SizedBox(height: 30),
                  Consumer(
                    builder: (context, ref, child) {
                      final authService = ref.watch(authServiceProvider);
                      return ElevatedButton(
                        onPressed: authService.isLoading
                            ? null
                            : () async {
                                await ref
                                    .read(authServiceProvider)
                                    .signOut(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                        child: authService.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign Out'),
                      );
                    },
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: Text('No data available'),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  AppUser.User parseUserData(String data) {
    try {
      // Trim whitespace and remove any special characters that might cause issues
      String cleanData = data.trim();

      // Check if the data is already in JSON format
      Map<String, dynamic> jsonData;

      try {
        // Try to parse the data as JSON directly
        jsonData = jsonDecode(cleanData);
      } catch (e) {
        // If that fails, check if the data needs additional cleaning
        // Sometimes API responses can include equals signs or other prefixes
        if (cleanData.contains("={")) {
          cleanData = cleanData.substring(cleanData.indexOf("={") + 1);
          jsonData = jsonDecode(cleanData);
        } else {
          // If all parsing attempts fail, throw an error
          throw FormatException("Could not parse data as JSON");
        }
      }

      // Create user from parsed JSON data
      return AppUser.User(
        uuid: jsonData['uuid'] ?? '',
        name: jsonData['name'] ?? '',
        email: jsonData['email'] ?? '',
        createdAt: jsonData['created_at'] ?? '',
        updatedAt: jsonData['updated_at'] ?? '',
        deletedAt: jsonData['deleted_at'] ?? '',
        username: jsonData['username'] ?? '',
        bio: jsonData['bio'] ?? '',
        dateOfBirth: jsonData['date_of_birth'] ?? '',
        gender: jsonData['gender'] ?? '',
        phoneNumber: jsonData['phone_number'] ?? '',
      );
    } catch (e) {
      // If all else fails
      throw FormatException("Failed to parse user data: $e\nRaw data: $data");
    }
  }
}
