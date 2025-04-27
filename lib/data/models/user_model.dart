import 'package:flutter_riverpod/flutter_riverpod.dart';

class User {
  final String name;
  final String email;
  final String uuid;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String username;
  final String bio;
  final String dateOfBirth;
  final String gender;
  final String phoneNumber;

  bool isOnline;

  User({
    required this.name,
    required this.email,
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.username,
    required this.bio,
    required this.dateOfBirth,
    required this.gender,
    required this.phoneNumber,
    this.isOnline = false,
  });

  @override
  String toString() {
    return '''
    User {
      uuid: $uuid,
      name: $name,
      email: $email,
      createdAt: $createdAt,
      updatedAt: $updatedAt,
      deletedAt: $deletedAt,
      username: $username,
      bio: $bio,
      dateOfBirth: $dateOfBirth,
      gender: $gender,
      phoneNumber: $phoneNumber
    }
    ''';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      deletedAt: json['deleted_at'] ?? '',
      username: json['username'] ?? '',
      bio: json['bio'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      gender: json['gender'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
    );
  }
  // Map<String, dynamic> toJson() {
  //   return {
  //     'uuid': uuid,
  //     'name': name,
  //     'email': email,
  //     'created_at': createdAt,
  //     'updated_at': updatedAt,
  //     'deleted_at': deletedAt,
  //     'username': username,
  //     'bio': bio,
  //     'date_of_birth': dateOfBirth,
  //     'gender': gender,
  //     'phone_number': phoneNumber,
  //   };
  // }

  static Map<String, dynamic> toJsonFromMap(Map<String, User> data) {
    return data.map((key, user) => MapEntry(key, {
          'uuid': user.uuid,
          'name': user.name,
          'email': user.email,
          'created_at': user.createdAt,
          'updated_at': user.updatedAt,
          'deleted_at': user.deletedAt,
          'username': user.username,
          'bio': user.bio,
          'date_of_birth': user.dateOfBirth,
          'gender': user.gender,
          'phone_number': user.phoneNumber,
        }));
  }
}

final currentReceiverProvider = StateProvider<User?>((ref) => null);
