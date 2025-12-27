// lib/services/patient_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class PatientService {
  static const String baseUrl = 'https://hospitalapp.darkube.app';

  static Future<List<Map<String, dynamic>>> getDoctorPatients() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/doctor/patients'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('خطا در دریافت بیماران');
    }
  }
}
