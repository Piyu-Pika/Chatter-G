// api routes to send the data to go api to save in the database
import 'package:chatterg/data/datasources/local/local_data_source.dart';
import 'package:chatterg/data/models/user_model.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MongoDBDataSource {
  final baseUrl = dotenv.env['BASE_URL'] ?? 'https://localhost:8080';
  final dio.Dio _dio = dio.Dio();

  Future<String> saveData(data) async {
    // Convert the data to JSON format
    final String jsonData = jsonEncode(data);
    // Print the JSON data for debugging
    print('JSON Data: $jsonData');

    try {
      final response = await _dio.post('$baseUrl/api/v1/users/ ',
          options: dio.Options(
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
          ),
          data: jsonData,
          queryParameters: <String, dynamic>{
            'uuid': data['uuid'],
            'name': data['name'],
            'email': data['email'],
            'createdAt': data['created_at'],
            'updatedAt': data['updated_at'],
            'username': data['username'],
            'bio': data['bio'],
            'date_of_birth': data['date_of_birth'],
            'gender': data['gender'],
            'phone_number': data['phone_number'],
            'profile_pic': data['profile_pic'],
          });

      if (response.statusCode == 200) {
        return response.data.toString();
      } else {
        throw Exception('Failed to save data');
      }
    } catch (e) {
      throw Exception('Failed to save data: $e');
    }
  }

  Future<void> updateUserStatus(String uuid, bool isOnline) async {
    try {
      final response = await _dio.patch(
        '$baseUrl/user',
        options: dio.Options(
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
        data: jsonEncode({
          'uuid': uuid,
          'is_online': isOnline,
        }),
        queryParameters: <String, dynamic>{
          'uuid': uuid,
          'is_online': isOnline,
        },
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to update user status');
      }
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  Future<List<User>> getData(uuid) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/v1/users/',
        options: dio.Options(
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
        queryParameters: <String, dynamic>{
          'uuid': uuid,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final List<User> users = data.map((userJson) {
          return User(
            name: userJson['name'],
            email: userJson['email'],
            uuid: userJson['uuid'],
            createdAt: userJson['created_at'],
            updatedAt: userJson['updated_at'],
            deletedAt: userJson['deleted_at'],
            username: userJson['username'],
            bio: userJson['bio'],
            dateOfBirth: userJson['date_of_birth'],
            gender: userJson['gender'],
            phoneNumber: userJson['phone_number'],
          );
        }).toList();

        // Print the list of users for debugging
        print('Users: $users'); // Debugging line

        return users;
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  Future<int?> Forcefullystartingserver() async {
    try {
      final response = await _dio.get(
        'https://chatterg-.leapcell.app/health',
        options: dio.Options(
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.statusCode;
      } else {
        throw Exception('Failed to save data');
      }
    } catch (e) {
      throw Exception('Failed to check server health: $e');
    }
  }

  Future<User> getUserData(uuid) async {
    try {
      final response = await _dio.get(
        '$baseUrl/user',
        options: dio.Options(
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
        queryParameters: <String, dynamic>{
          'uuid': uuid,
        },
      );
      print('Response: ${response.data}'); // Debugging line

      if (response.statusCode == 200) {
        final data = response.data;
        final user = User(
          name: data['name'],
          email: data['email'],
          uuid: data['uuid'],
          createdAt: data['created_at'],
          updatedAt: data['updated_at'],
          deletedAt: data['deleted_at'],
          username: data['username'],
          bio: data['bio'],
          dateOfBirth: data['date_of_birth'],
          gender: data['gender'],
          phoneNumber: data['phone_number'],
        );

        // Print the user for debugging
        print('User: $user'); // Debugging line

        // Save the data in the local database
        await LocalDataSource().saveData(user);
        return user;
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  //patch the data
  Future<int?> patchData(data) async {
    // Convert the data to JSON format
    final String jsonData = jsonEncode(data);
    // Print the JSON data for debugging
    print('JSON Data: $jsonData');

    try {
      final response = await _dio.patch('$baseUrl/user',
          options: dio.Options(
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
          ),
          data: jsonData,
          queryParameters: <String, dynamic>{
            'uuid': data['uuid'],
            'name': data['name'],
            'email': data['email'],
            'createdAt': data['created_at'],
            'updatedAt': data['updated_at'],
          });

      if (response.statusCode == 200) {
        return response.data;
      } else {
        // Log the response for debugging
        print('Error Response: ${response.statusCode} - ${response.data}');
        throw Exception(
            'Failed to save data: Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      // Log the exception for debugging
      print('Exception occurred: $e');
      throw Exception('Failed to save data: $e');
    }
  }
}
