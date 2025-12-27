import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

class ResetPasswordPage extends StatefulWidget {
  final String resetToken;

  const ResetPasswordPage({
    super.key,
    required this.resetToken,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/reset-password'),
            headers: {
              'Authorization': 'Bearer ${widget.resetToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'newPassword': _passwordController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز عبور با موفقیت تغییر کرد')),
        );

        // بازگشت کامل به ابتدای برنامه (مثلاً لاگین)
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        final body = jsonDecode(res.body);
        final msg = body['detail'] ?? 'خطا در تغییر رمز عبور';
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
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
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
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: const [
          Icon(Icons.lock_reset, size: 60, color: Colors.white),
          SizedBox(height: 8),
          Text(
            'تعیین رمز عبور جدید',
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            _passwordField(
              controller: _passwordController,
              label: 'رمز عبور جدید',
            ),
            const SizedBox(height: 14),
            _passwordField(
              controller: _confirmController,
              label: 'تکرار رمز عبور',
              confirm: true,
            ),
            const SizedBox(height: 28),
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
        if (confirm && v != _passwordController.text) {
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
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
        onPressed: _isLoading ? null : _submit,
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
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'ثبت رمز جدید',
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
}
