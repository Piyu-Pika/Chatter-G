// api routes to send the data to go api to save in the database
import 'package:http/http.dart' as http;
import 'dart:convert';

class CockroachDBDataSource {
  Future<String> saveData(String data) async {
    final response = await http.post(
      Uri.parse('https://godzilla-api.herokuapp.com/api/v1/godzilla'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: data,
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to save data');
    }
  }

  Future<String> getData() async {
    final response = await http.get(
      Uri.parse('https://godzilla-api.herokuapp.com/api/v1/godzilla'),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load data');
    }
  }
}
