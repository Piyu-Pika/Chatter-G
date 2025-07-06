// filepath: d:/ChatterG/lib/presentation/pages/profile_screen/profileScreenProvider.dart
import 'package:chatterg/data/models/user_model.dart';
import 'package:chatterg/data/datasources/remote/api_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ProfileScreenProvider using Riverpod
final profileScreenProvider = ChangeNotifierProvider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileScreenState(apiClient: apiClient);
});

// ApiClient provider
final apiClientProvider = Provider((ref) => ApiClient());

// ProfileScreenState class
class ProfileScreenState extends ChangeNotifier {
  final ApiClient apiClient;
  User? user;

  ProfileScreenState({required this.apiClient, this.user});

  // Fetch user profile by UUID
  Future<void> fetchUserProfile(String uuid) async {
    try {
      final userData = await apiClient.getUserByUUID(uuid: uuid);
      user = User.fromJson(userData);
      notifyListeners();
    } catch (e) {
      print('Error fetching user profile: $e');
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
      user = User.fromJson(updatedData);
      notifyListeners();
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }
}

// // Example usage in a Flutter widget
// class ProfileEditScreen extends ConsumerWidget {
//   final String userUuid;

//   ProfileEditScreen({required this.userUuid});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final profileState = ref.watch(profileScreenProvider);

//     return Scaffold(
//       appBar: AppBar(title: Text('Edit Profile')),
//       body: profileState.user == null
//           ? Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   TextFormField(
//                     initialValue: profileState.user?.name,
//                     decoration: InputDecoration(labelText: 'Name'),
//                     onChanged: (value) {
//                       profileState.user = profileState.user?.copyWith(name: value);
//                     },
//                   ),
//                   TextFormField(
//                     initialValue: profileState.user?.bio,
//                     decoration: InputDecoration(labelText: 'Bio'),
//                     onChanged: (value) {
//                       profileState.user = profileState.user?.copyWith(bio: value);
//                     },
//                   ),
//                   ElevatedButton(
//                     onPressed: () async {
//                       await profileState.updateUserProfile(
//                         uuid: userUuid,
//                         name: profileState.user?.name,
//                         bio: profileState.user?.bio,
//                       );
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Profile updated successfully')),
//                       );
//                     },
//                     child: Text('Save Changes'),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
