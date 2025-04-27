class UserEntity {
  final String name;
  final String email;
  final String uuid;
  final String createdAt;
  final String updatedAt;
  final String deletedAt;
  final String username;
  final String bio;
  final String dateOfBirth;
  final String gender;
  final String phoneNumber;

  UserEntity({
    required this.name,
    required this.email,
    required this.uuid,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.username,
    required this.bio,
    required this.dateOfBirth,
    required this.gender,
    required this.phoneNumber,
  });
}
