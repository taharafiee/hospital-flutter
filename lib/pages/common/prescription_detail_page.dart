import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class MoshakhasotNoskhe extends StatefulWidget {
  final String prescriptionId;

  const MoshakhasotNoskhe({
    super.key,
    required this.prescriptionId,
  });

  @override
  State<MoshakhasotNoskhe> createState() => _MoshakhasotNoskheState();
}

class _MoshakhasotNoskheState extends State<MoshakhasotNoskhe> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  Future<void> _loadPrescription() async {
    try {
      final token = await AuthService.getToken();

      final res = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/prescriptions/${widget.prescriptionId}",
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          _data = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'خطا در دریافت اطلاعات نسخه';
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'مشکل در ارتباط با سرور';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات نسخه'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      Text(
                        'نام بیمار: ${_data!['patientName'] ?? '—'}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'نام پزشک: ${_data!['doctorName'] ?? '—'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'بیماری: ${_data!['disease'] ?? '—'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'تاریخ نسخه: ${_data!['prescriptionDate'] ?? '—'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'بیمارستان: ${_data!['hospital'] ?? '—'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'داروها و توضیحات:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _data!['details'] ?? '—',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                          child: const Text(
                            'بازگشت',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
