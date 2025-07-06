import 'dart:developer';

import 'package:chatterg/data/models/user_model.dart';
import 'package:dio/dio.dart';

import 'package:dio/dio.dart' as dio;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// API client class to interact with the Godzilla-Go backend API
class ApiClient {
  final Dio _dio;
  // final String baseUrl = 'https://gochat.leapcell.app/';

  // Constructor initializes Dio with base URL and default configurations
  ApiClient({String? baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ??
              (dotenv.env['BASE_URL'] ??
                  'https://chatterg-go-production.up.railway.app'),
          connectTimeout: Duration(seconds: 30), // Increased timeout
          receiveTimeout: Duration(seconds: 30), // Increased timeout
          sendTimeout: Duration(seconds: 30), // Added send timeout
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) {
            // Accept status codes from 200-299 and some 4xx for proper error handling
            return status != null && status < 500;
          },
        )) {
    // Add interceptors for better debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      error: true,
    ));
  }

  // Helper method to handle API errors
  Future<String?> _handleError(DioException error) async {
    print('API Error: ${error.type}');
    print('Error message: ${error.message}');
    print('Response data: ${error.response?.data}');

    if (error.response != null) {
      // Handle different status codes
      switch (error.response!.statusCode) {
        case 400:
          return 'Bad request: ${error.response!.data['error'] ?? 'Invalid data'}';
        case 401:
          return 'Unauthorized: Please check your credentials';
        case 403:
          return 'Forbidden: Access denied';
        case 404:
          return 'Not found: The requested resource was not found';
        case 422:
          return 'Validation error: ${error.response!.data['error'] ?? 'Invalid input'}';
        case 500:
          return 'Server error: Please try again later';
        default:
          return error.response!.data['error']?.toString() ??
              'Unknown error occurred';
      }
    }

    // Handle connection errors
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout: Please check your internet connection';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout: Server is taking too long to respond';
      case DioExceptionType.sendTimeout:
        return 'Send timeout: Failed to send data to server';
      case DioExceptionType.badResponse:
        return 'Bad response from server';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      case DioExceptionType.connectionError:
        return 'Connection error: Please check your internet connection and server status';
      case DioExceptionType.unknown:
        return 'Unknown error: ${error.message}';
      default:
        return error.message ?? 'Unknown error occurred';
    }
  }

  // User Operations

  // Forcefully start the server (for testing purposes)
  Future<int?> Forcefullystartingserver() async {
    try {
      final response = await _dio.get(
        '/health', // Use relative path since baseUrl is set
        options: dio.Options(
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.statusCode;
      } else {
        throw Exception(
            'Server health check failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(
          'Failed to check server health: ${await _handleError(e)}');
    } catch (e) {
      throw Exception('Failed to check server health: $e');
    }
  }

  // Create a new user
  Future<Map<String, dynamic>> createUser({
    required String uuid,
    required String name,
    required String email,
  }) async {
    try {
      final data = {
        'uuid': uuid, //required
        'name': name, //required
        'email': email, //required
      };

      print('Creating user with data: $data');

      final response = await _dio.post(
        '/api/v1/users', // Use relative path
        data: data,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Get all users - Fixed return type casting
  Future<List<User>> getUsers() async {
    try {
      final response = await _dio.get('/api/v1/users');

      if (response.data['data'] is List) {
        final List<dynamic> usersJson = response.data['data'] as List<dynamic>;
        return usersJson
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Unexpected response format: data is not a list');
      }
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Get user by UUID
  Future<Map<String, dynamic>> getUserByUUID({required String uuid}) async {
    try {
      if (uuid.isEmpty) {
        throw Exception('UUID cannot be empty');
      }

      final response = await _dio.get('/api/v1/users/$uuid');

      if (response.data['data'] != null) {
        log('User data found in response: ${response.data['data']}');
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('User data not found in response');
      }
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Get user by username - Fixed variable name typo
  Future<Map<String, dynamic>> getUserByUsername(String username) async {
    try {
      if (username.isEmpty) {
        throw Exception('Username cannot be empty');
      }

      final response = await _dio.get(
          '/api/v1/users/username/$username'); // Fixed: was using base64Url instead of _baseUrl

      if (response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('User data not found in response');
      }
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Update user information - Fixed path to use baseUrl
  Future<Map<String, dynamic>> updateUser({
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
      if (uuid.isEmpty) {
        throw Exception('UUID cannot be empty');
      }

      final data = <String, dynamic>{};
      if (name != null && name.isNotEmpty) data['name'] = name;
      if (surname != null && surname.isNotEmpty) data['surname'] = surname;
      if (username != null && username.isNotEmpty) data['username'] = username;
      if (bio != null && bio.isNotEmpty) data['bio'] = bio;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty)
        data['date_of_birth'] = dateOfBirth;
      if (gender != null && gender.isNotEmpty) data['gender'] = gender;
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        data['phone_number'] = phoneNumber;
      if (profilePic != null && profilePic.isNotEmpty)
        data['profile_pic'] = profilePic;

      if (data.isEmpty) {
        throw Exception('No data provided for update');
      }

      print('Updating user with data: $data');

      final response = await _dio.put(
        '/api/v1/users/$uuid', // Fixed: added baseUrl path
        data: data,
      );

      if (response.data['data'] != null) {
        return response.data['data'] as Map<String, dynamic>;
      } else {
        return response.data as Map<String, dynamic>;
      }
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Delete a user
  Future<void> deleteUser(String uuid) async {
    try {
      if (uuid.isEmpty) {
        throw Exception('UUID cannot be empty');
      }

      await _dio.delete('/api/v1/users/$uuid');
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Update user online status - Fixed path
  Future<void> updateUserOnlineStatus(String uuid, bool isOnline) async {
    try {
      if (uuid.isEmpty) {
        throw Exception('UUID cannot be empty');
      }

      await _dio.patch(
        '/api/v1/users/$uuid/status', // Fixed: added proper API path
        data: {'is_online': isOnline},
      );
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Search users by query
  Future<List<dynamic>> searchUsers(String query, {int limit = 20}) async {
    try {
      if (query.isEmpty) {
        throw Exception('Search query cannot be empty');
      }

      final response = await _dio.get(
        '/api/v1/users/search',
        queryParameters: {'q': query, 'limit': limit},
      );

      if (response.data['data'] is List) {
        return response.data['data'] as List<dynamic>;
      } else {
        throw Exception('Unexpected response format: data is not a list');
      }
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Get online users
  Future<List<dynamic>> getOnlineUsers() async {
    try {
      final response = await _dio.get('/api/v1/users/online');

      if (response.data['data'] is List) {
        return response.data['data'] as List<dynamic>;
      } else {
        throw Exception('Unexpected response format: data is not a list');
      }
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Messaging Operations

  // Send a chat message
  Future<void> sendMessage({
    required String senderId,
    required String recipientId,
    required String content,
    required DateTime timestamp,
  }) async {
    try {
      if (senderId.isEmpty || recipientId.isEmpty || content.isEmpty) {
        throw Exception('Sender ID, recipient ID, and content cannot be empty');
      }

      await _dio.post(
        '/api/v1/messages',
        data: {
          'sender_id': senderId,
          'recipient_id': recipientId,
          'content': content,
          'timestamp': timestamp.toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Get offline messages for a user
  Future<List<dynamic>> getOfflineMessages(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      final response = await _dio.get(
        '/api/v1/messages/offline',
        queryParameters: {'userID': userId},
      );

      if (response.data is List) {
        return response.data as List<dynamic>;
      } else if (response.data['data'] is List) {
        return response.data['data'] as List<dynamic>;
      } else {
        throw Exception('Unexpected response format');
      }
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Delete offline messages for a user
  Future<void> deleteOfflineMessages(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID cannot be empty');
      }

      await _dio.delete(
        '/api/v1/messages/offline',
        queryParameters: {'userID': userId},
      );
    } on DioException catch (e) {
      throw Exception(await _handleError(e));
    }
  }

  // Test connection method
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
