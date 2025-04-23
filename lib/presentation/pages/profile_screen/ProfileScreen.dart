// import 'dart:convert';

import 'package:chatterg/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart' as AppUser;
// import '../../providers/auth_provider.dart';
import '../../../data/datasources/remote/cockroachdb_data_source.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _cockroachdbDataSource = CockroachDBDataSource();
  late Future<AppUser.User> _userDataFuture = Future.value(AppUser.User(
    uuid: '',
    name: '',
    email: '',
    createdAt: '',
    updatedAt: '',
    deletedAt: '',
    username: '',
    bio: '',
    dateOfBirth: '',
    gender: '',
    phoneNumber: '',
  ));

  // Hardcoded test data - you can remove this once the API is working correctly
  final String testData = '''
    {
      "uuid": "162BgS74dhM1Rm9KQHQ4oXbdCoz1",
      "name": "John Doe",
      "email": "testn@gmail.com",
      "created_at": "",
      "updated_at": "",
      "deleted_at": "Z",
      "username": "",
      "bio": "",
      "date_of_birth": "",
      "gender": "",
      "phone_number": ""
    }
  ''';

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    final authProvider =
        ref.read(authServiceProvider); // Assuming authProvider is defined
    final userId = await authProvider.getUid();
    setState(() {
      print("User ID: $userId"); // Debug print
      _userDataFuture = _cockroachdbDataSource.getUserData(userId);
      print("User data future: $_userDataFuture"); // Debug print
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
        body: FutureBuilder<AppUser.User>(
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
                    fontSize: 16,
                  ),
                ),
              );
            } else if (snapshot.hasData) {
              final user = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user.name.isNotEmpty ? user.name : 'No Name Provided',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Divider(
                      color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      thickness: 1,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow('UUID', user.uuid, isDarkMode),
                    _buildInfoRow('Username', user.username, isDarkMode),
                    _buildInfoRow('Bio', user.bio, isDarkMode),
                    _buildInfoRow(
                        'Date of Birth', user.dateOfBirth, isDarkMode),
                    _buildInfoRow('Gender', user.gender, isDarkMode),
                    _buildInfoRow('Phone Number', user.phoneNumber, isDarkMode),
                    _buildInfoRow('Created At', user.createdAt, isDarkMode),
                    _buildInfoRow('Updated At', user.updatedAt, isDarkMode),
                  ],
                ),
              );
            } else {
              return const Center(
                child: Text('No data available'),
              );
            }
          },
        ));
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
