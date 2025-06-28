import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

import '../../models/user_model.dart';

class LocalDataSource {
  static final LocalDataSource _instance = LocalDataSource._internal();
  factory LocalDataSource() => _instance;
  LocalDataSource._internal();

  // Step 1: Initialize the secure storage instance
  static const _secureStorage = FlutterSecureStorage();

  // Step 2: Define keys for secure storage
  static const String _keyName = 'name';
  static const String _keyEmail = 'email';
  static const String _keyUuid = 'uuid';
  static const String _keyCreatedAt = 'created_at';
  static const String _keyUpdatedAt = 'updated_at';
  static const String _keyDeletedAt = 'deleted_at';
  static const String _keyUsername = 'username';
  static const String _keyBio = 'bio';
  static const String _keyDateOfBirth = 'date_of_birth';
  static const String _keyGender = 'gender';
  static const String _keyPhoneNumber = 'phone_number';
  static const String _keyProfilePic = 'profile_pic';
  static const String _keyLastSeen = 'last_seen';
  static const String _keySurname = 'surname';

  // Step 3: Save data to secure storage
  Future<void> saveData(User data) async {
    try {
      final Map<String, String> userMap = {
        _keyName: data.name,
        _keyEmail: data.email,
        _keyUuid: data.uuid,
        _keySurname: data.surname ?? '',
        _keyProfilePic: data.profilePic ?? '',
        _keyLastSeen: data.lastSeen?.toIso8601String() ?? '',
        _keyUsername: data.username ?? '',
        _keyBio: data.bio ?? '',
        _keyDateOfBirth: data.dateOfBirth ?? '',
        _keyGender: data.gender ?? '',
        _keyPhoneNumber: data.phoneNumber ?? '',
      };

      for (var entry in userMap.entries) {
        await _secureStorage.write(key: entry.key, value: entry.value);
      }
      print("User data saved to secure storage successfully.");
    } catch (e) {
      print("Error saving data to secure storage: $e");
    }
  }

  // Step 4: Retrieve data from secure storage
  Future<User?> getUser() async {
    try {
      final String? name = await _secureStorage.read(key: _keyName);
      final String? email = await _secureStorage.read(key: _keyEmail);
      final String? uuid = await _secureStorage.read(key: _keyUuid);
      final String? createdAt = await _secureStorage.read(key: _keyCreatedAt);
      final String? updatedAt = await _secureStorage.read(key: _keyUpdatedAt);
      final String? deletedAt = await _secureStorage.read(key: _keyDeletedAt);
      final String? surname = await _secureStorage.read(key: _keySurname);
      final String? profilePic = await _secureStorage.read(key: _keyProfilePic);
      final String? lastSeen = await _secureStorage.read(key: _keyLastSeen);
      final String? username = await _secureStorage.read(key: _keyUsername);
      final String? bio = await _secureStorage.read(key: _keyBio);
      final String? dateOfBirth =
          await _secureStorage.read(key: _keyDateOfBirth);
      final String? gender = await _secureStorage.read(key: _keyGender);
      final String? phoneNumber =
          await _secureStorage.read(key: _keyPhoneNumber);

      if (name != null && email != null && uuid != null) {
        return User(
          name: name,
          email: email,
          uuid: uuid,
          surname: surname ?? '',
          profilePic: profilePic ?? '',
          lastSeen: DateTime.parse(lastSeen ?? ''),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),

          // createdAt: createdAt ?? '',
          // updatedAt: updatedAt ?? '',
          // deletedAt: deletedAt,
          username: username ?? '',
          bio: bio ?? '',
          dateOfBirth: dateOfBirth ?? '',
          gender: gender ?? '',
          phoneNumber: phoneNumber ?? '',
        );
      }
      return null;
    } catch (e) {
      print("Error retrieving user from secure storage: $e");
      return null;
    }
  }

  // Step 5: Update data in secure storage
  Future<void> updateData(Map<String, String> data) async {
    try {
      for (var entry in data.entries) {
        await _secureStorage.write(key: entry.key, value: entry.value);
      }
    } catch (e) {
      print("Error updating data in secure storage: $e");
    }
  }

  // Step 6: Delete data from secure storage
  Future<void> clearData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      print("Error clearing data from secure storage: $e");
    }
  }
}
