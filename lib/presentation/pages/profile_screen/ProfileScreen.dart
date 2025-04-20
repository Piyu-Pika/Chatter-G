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
  final _currentUser = FirebaseAuth.instance.currentUser;
  late Future<String> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = CockroachDBDataSource().getData(_currentUser!.uid);
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
            final user = parseUserData(data);

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child:
                        const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Name: ${user.name}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Email: ${user.email}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'UUID: ${user.uuid}',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
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

  AppUser.User parseUserData(String data) {
    final jsonData = jsonDecode(data);
    return AppUser.User(
      name: jsonData['name'],
      email: jsonData['email'],
      uuid: jsonData['uuid'],
      createdAt: jsonData['created_at'],
      updatedAt: jsonData['updated_at'],
      deletedAt: jsonData['deleted_at'],
      username: jsonData['username'],
      bio: jsonData['bio'],
      dateOfBirth: jsonData['date_of_birth'],
      gender: jsonData['gender'],
      phoneNumber: jsonData['phone_number'],
    );
  }
}
