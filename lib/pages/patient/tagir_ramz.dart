import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

class TagirRamzPage extends StatefulWidget {
  const TagirRamzPage({super.key});

  @override
  State<TagirRamzPage> createState() => _TagirRamzPageState();
}

class _TagirRamzPageState extends State<TagirRamzPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        _showSnack('کاربر وارد نشده است');
        return;
      }

      final res = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/change-password"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "newPassword": _newPasswordController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز عبور با موفقیت تغییر کرد')),
        );
        Navigator.pop(context);
      } else {
        final msg =
            jsonDecode(res.body)['detail'] ?? 'خطا در تغییر رمز عبور';
        _showSnack(msg);
      }
    } on SocketException {
      _showSnack('عدم اتصال به سرور');
    } on TimeoutException {
      _showSnack('پاسخ سرور طول کشید');
    } catch (_) {
      _showSnack('خطای غیرمنتظره');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _form(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Icon(Icons.lock, size: 52, color: Colors.white),
          const SizedBox(height: 8),
          const Text(
            'تغییر رمز عبور',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            _passwordField(
              controller: _newPasswordController,
              label: 'رمز عبور جدید',
            ),
            const SizedBox(height: 14),
            _passwordField(
              controller: _confirmPasswordController,
              label: 'تأیید رمز عبور',
              confirm: true,
            ),
            const SizedBox(height: 24),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    bool confirm = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !_showPassword,
      style: const TextStyle(color: Colors.white),
      validator: (v) {
        if (v == null || v.length < 8) {
          return 'حداقل ۸ کاراکتر';
        }
        if (confirm && v != _newPasswordController.text) {
          return 'رمزها یکسان نیستند';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: () =>
              setState(() => _showPassword = !_showPassword),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.lightBlue),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'تغییر رمز',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
