import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class DoctorService {
  static const String baseUrl =
      'https://hospitalapp.darkube.app'; // IP سرور FastAPI

  // ===================== PROFILE =====================
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('خطا در دریافت اطلاعات پزشک');
    }
  }

  // ===================== APPOINTMENTS =====================
  static Future<List<dynamic>> getAppointments() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/doctor/appointments'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('خطا در دریافت بیماران نوبت‌دار');
    }
  }
}
