import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class PrescriptionPage extends StatefulWidget {
  final String patientCodeMelli;

  const PrescriptionPage({
    super.key,
    required this.patientCodeMelli,
  });

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  final TextEditingController _detailsController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String _disease = '';

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  // ================= LOAD PATIENT DATA =================
  Future<void> _loadPatientData() async {
    try {
      final token = await AuthService.getToken();

      final res = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/doctor/patients/${widget.patientCodeMelli}",
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _disease = data['disease'] ?? '';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'اطلاعات بیمار یافت نشد';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'خطا در ارتباط با سرور';
        _loading = false;
      });
    }
  }

  // ================= SAVE PRESCRIPTION =================
  Future<void> _savePrescription() async {
    if (_detailsController.text.trim().isEmpty) {
      _snack('جزئیات نسخه الزامی است', Colors.red);
      return;
    }

    setState(() => _saving = true);

    try {
      final token = await AuthService.getToken();

      final body = {
        "patientCodeMelli": widget.patientCodeMelli,
        "disease": _disease,
        "details": _detailsController.text.trim(),
      };

      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/prescriptions"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack('نسخه با موفقیت ثبت شد', Colors.green);
        Navigator.pop(context, true);
      } else {
        _snack('خطا در ثبت نسخه (${res.statusCode})', Colors.red);
      }
    } catch (_) {
      _snack('مشکل در ارتباط با سرور', Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.25),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ثبت نسخه',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoCard('بیماری', _disease),
                      const SizedBox(height: 16),

                      const Text(
                        '📝 جزئیات نسخه',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      TextField(
                        controller: _detailsController,
                        maxLines: 6,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const Spacer(),

                      _saveButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _saving ? null : _savePrescription,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: const Center(
              child: Text(
                'ثبت نسخه',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
}
