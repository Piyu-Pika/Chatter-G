// api routes to send the data to go api to save in the database
import 'package:chatterg/data/datasources/local/local_data_source.dart';
import 'package:dio/dio.dart' as dio;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CockroachDBDataSource {
  final baseUrl = dotenv.env['BASE_URL'] ?? 'https://localhost:8080';
  final Map<String, dynamic> data = Map<String, dynamic>.from({
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

  Future<String> getData() async {
    try {
      final response = await _dio.get(
        'https://localhost:8080/api/v1/godzilla',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final name = data['name'];
        final email = data['email'];
        final uuid = data['uuid'];

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
        final name = data['name'];
        final email = data['email'];
        final uuid = data['uuid'];

        // save the data in the database
        await LocalDataSource().saveData(data);
        return response.data.toString();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }
}
