import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class PrescriptionPage extends StatefulWidget {
  final int visitId; // 👈 خیلی مهم

  const PrescriptionPage({
    super.key,
    required this.visitId,
  });

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  final TextEditingController _detailsController = TextEditingController();

  bool _saving = false;

  // ================= SAVE PRESCRIPTION =================
  Future<void> _savePrescription() async {
    if (_detailsController.text.trim().isEmpty) {
      _snack('جزئیات نسخه الزامی است', Colors.red);
      return;
    }

    setState(() => _saving = true);

    try {
      final token = await AuthService.getToken();

      final res = await http.put(
        Uri.parse(
          "${ApiConfig.baseUrl}/prescriptions/${widget.visitId}",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "details": _detailsController.text.trim(),
        }),
      );

      if (res.statusCode == 200) {
        _snack('نسخه با موفقیت ثبت شد', Colors.green);
        Navigator.pop(context, true);
      } else {
        final body = jsonDecode(res.body);
        _snack(body['detail'] ?? 'خطا در ثبت نسخه', Colors.red);
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            child: Center(
              child: _saving
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text(
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
