// lib/services/login_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginService {
  static const String baseUrl = 'https://hospitalapp.darkube.app';

  static Future<Map<String, dynamic>> login({
    required String codeMelli,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'codeMelli': codeMelli,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('login_failed');
    }
  }
}

