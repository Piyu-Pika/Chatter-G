// filepath: d:/ChatterG/lib/presentation/pages/profile_screen/profileScreenProvider.dart
import 'package:chatterg/data/models/user_model.dart';
import 'package:chatterg/data/datasources/remote/api_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_log/dev_log.dart';


// ProfileScreenProvider using Riverpod
final reciverprofileScreenProvider = ChangeNotifierProvider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReciverProfileScreenState(apiClient: apiClient);
});

// ApiClient provider
final apiClientProvider = Provider((ref) => ApiClient());

// ProfileScreenState class
class ReciverProfileScreenState extends ChangeNotifier {
  final ApiClient apiClient;
  AppUser? user;

  ReciverProfileScreenState({required this.apiClient, this.user});

  // Fetch user profile by UUID
  Future<void> fetchUserProfile(String uuid) async {
    try {
      final userData = await apiClient.getUserByUUID(uuid: uuid);
      user = AppUser.fromJson(userData);
      notifyListeners();
    } catch (e) {
      L.e('Error fetching user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uuid,
    String? name,
    String? surname,
    String? username,
    String? bio,
    String? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? profilePic,
  }) async {
    try {
      final updatedData = await apiClient.updateUser(
        uuid: uuid,
        name: name,
        surname: surname,
        username: username,
        bio: bio,
        dateOfBirth: dateOfBirth,
        gender: gender,
        phoneNumber: phoneNumber,
        profilePic: profilePic,
      );
      user = AppUser.fromJson(updatedData);
      notifyListeners();
    } catch (e) {
      L.e('Error updating user profile: $e');
    }
  }
}
