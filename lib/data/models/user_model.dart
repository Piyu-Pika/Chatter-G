import 'package:flutter_riverpod/flutter_riverpod.dart';

class User {
  final String uuid; // Firebase UID
  final String name; // Full name
  final String? surname; // Surname/Last name
  final String email; // Email address
  final DateTime createdAt; // Account creation timestamp
  final DateTime? updatedAt; // Last update timestamp
  final DateTime? deletedAt; // Soft delete timestamp
  final String? username; // Unique username
  final String? bio; // User biography
  final String dateOfBirth; // Date of birth (YYYY-MM-DD format) - Made nullable
  final String? gender; // Gender - Made nullable
  final String? phoneNumber; // Phone number
  final String? profilePic; // Profile picture URL
  final bool? isOnline; // Online status
  final DateTime? lastSeen; // Last seen timestamp

  User({
    required this.uuid,
    required this.name,
    required this.email,
    required this.createdAt,
    this.surname,
    this.updatedAt,
    this.deletedAt,
    this.username,
    this.bio,
    required this.dateOfBirth, // Now nullable
    this.gender, // Now nullable
    this.phoneNumber,
    this.profilePic,
    this.isOnline,
    this.lastSeen,
  });

  @override
  String toString() {
    return '''
    User {
      uuid: $uuid,
      name: $name,
      surname: $surname,
      email: $email,
      createdAt: $createdAt,
      updatedAt: $updatedAt,
      deletedAt: $deletedAt,
      username: $username,
      bio: $bio,
      dateOfBirth: $dateOfBirth,
      gender: $gender,
      phoneNumber: $phoneNumber,
      profilePic: $profilePic,
      isOnline: $isOnline,
      lastSeen: $lastSeen
    }
    ''';
  }

  // Improved fromJson with better null handling
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      surname: json['surname']?.toString(),
      updatedAt: _parseDateTime(json['updated_at']),
      deletedAt: _parseDateTime(json['deleted_at']),
      username: json['username']?.toString(),
      bio: json['bio']?.toString(),
      dateOfBirth: json['date_of_birth'].toString(),
      gender: json['gender']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      profilePic: json['profile_pic']?.toString(),
      isOnline: json['is_online'] is bool ? json['is_online'] : null,
      lastSeen: _parseDateTime(json['last_seen']),
    );
  }

  // Helper method to safely parse DateTime
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      if (dateValue is String) {
        if (dateValue.isEmpty) return null;
        return DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        return dateValue;
      }
    } catch (e) {
      print('Error parsing date: $dateValue, error: $e');
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'surname': surname,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'username': username,
      'bio': bio,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'phone_number': phoneNumber,
      'profile_pic': profilePic,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }

  // Helper method to create a copy with updated fields
  User copyWith({
    String? uuid,
    String? name,
    String? surname,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? username,
    String? bio,
    String? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? profilePic,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return User(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePic: profilePic ?? this.profilePic,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  static Map<String, dynamic> toJsonFromMap(Map<String, User> data) {
    return data.map((key, user) => MapEntry(key, user.toJson()));
  }
}

final currentReceiverProvider = StateProvider<User?>((ref) => null);
