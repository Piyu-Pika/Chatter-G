// api routes to send the data to go api to save in the database
import 'package:chatterg/data/datasources/local/local_data_source.dart';
import 'package:chatterg/data/models/user_model.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CockroachDBDataSource {
  final baseUrl = dotenv.env['BASE_URL'] ?? 'https://localhost:8080';
  final Map<String, User> data = Map<String, User>.from({
    'name': '',
    'email': '',
    'uuid': '',
  });
  final dio.Dio _dio = dio.Dio();

  Future<String> saveData(data) async {
    try {
      final response = await _dio.post(
        '$baseUrl/save-data',
        options: dio.Options(
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data.toString();
      } else {
        throw Exception('Failed to save data');
      }
    } catch (e) {
      throw Exception('Failed to save data: $e');
    }
  }

  Future<String> getData(uuid) async {
    try {
      final response = await _dio.get(
        '$baseUrl/users',
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
        //print
        print(user);

        return response.data.toString();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  Future<String> getUserData() async {
    try {
      final response = await _dio.get(
        '$baseUrl/get-user-data',
      );

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
        //print
        print(user);

        // save the data in the database
        await LocalDataSource().saveData(response.data);
        return response.data.toString();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }
}
