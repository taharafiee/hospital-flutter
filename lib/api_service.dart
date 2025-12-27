import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = 'https://hospitalapp.darkube.app';
  // signup patient
  static Future<void> signupPatient(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'خطا در ثبت‌نام');
    }
  }

  // signup doctor
  static Future<void> signupDoctor(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctor/signup'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception(
          jsonDecode(response.body)['detail'] ?? 'خطا در ثبت‌نام پزشک');
    }
  }
}
