import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class PrescriptionService {
  // ================= DOCTOR: GET VISITS =================
  static Future<List<Map<String, dynamic>>> getDoctorPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception('Unauthorized');
    }

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/doctor/appointments"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load data');
    }

    final List data = jsonDecode(res.body);

    return data.map<Map<String, dynamic>>((e) {
      return {
        "id": e["id"], // 🔑 خیلی مهم
        "codeMelli": e["codeMelli"],
        "fullName": e["fullName"],
        "date": e["date"],
        "disease": e["disease"],
        "details": e["details"] ?? "",
      };
    }).toList();
  }

  // ================= DOCTOR: ADD PRESCRIPTION =================
  static Future<void> addPrescription({
    required int visitId,
    required String details,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      throw Exception('Unauthorized');
    }

    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/prescriptions/$visitId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "details": details,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to save prescription');
    }
  }
}
