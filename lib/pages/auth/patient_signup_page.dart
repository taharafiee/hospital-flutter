import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _codeMelliController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _diseaseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;

  // ---------- VALIDATION ----------
  bool _isValidNationalCode(String code) {
    if (!RegExp(r'^\d{10}$').hasMatch(code)) return false;
    int check = int.parse(code[9]);
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(code[i]) * (10 - i);
    }
    sum %= 11;
    return (sum < 2 && check == sum) || (sum >= 2 && check == 11 - sum);
  }

  // ---------- SIGNUP ----------
  Future<void> _signup() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = {
      "codeMelli": _codeMelliController.text.trim(),
      "fullName": _fullNameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "age": int.parse(_ageController.text.trim()),
      "disease": _diseaseController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    try {
      final res = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/signup"),
            headers: const {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ثبت‌نام با موفقیت انجام شد")),
        );
        Navigator.pop(context);
      } else {
        final msg =
            jsonDecode(res.body)['detail'] ?? "خطا در ثبت‌نام";
        _showSnack(msg, Colors.red);
      }
    } on SocketException {
      _showSnack("عدم اتصال به سرور", Colors.orange);
    } on TimeoutException {
      _showSnack("پاسخ سرور طول کشید", Colors.orange);
    } catch (_) {
      _showSnack("خطای غیرمنتظره", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43)],
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Icon(Icons.person_add, size: 48, color: Colors.white),
          const SizedBox(height: 8),
          const Text(
            "ثبت‌نام بیمار",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
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
            _field(_codeMelliController, "کد ملی",
                Icons.credit_card,
                keyboard: TextInputType.number,
                maxLength: 10,
                validator: (v) =>
                    v == null || !_isValidNationalCode(v)
                        ? "کد ملی نامعتبر است"
                        : null),
            _field(_fullNameController, "نام و نام خانوادگی",
                Icons.person,
                validator: (v) =>
                    v == null || v.isEmpty ? "نام را وارد کنید" : null),
            _field(_phoneController, "شماره موبایل", Icons.phone,
                keyboard: TextInputType.number,
                maxLength: 11,
                validator: (v) =>
                    v == null || v.length != 11
                        ? "شماره موبایل نامعتبر"
                        : null),
            _field(_ageController, "سن", Icons.cake,
                keyboard: TextInputType.number,
                validator: (v) {
                  final age = int.tryParse(v ?? "");
                  if (age == null || age <= 0 || age > 120) {
                    return "سن معتبر وارد کنید";
                  }
                  return null;
                }),
            _field(_diseaseController, "نوع بیماری",
                Icons.healing),
            _password(_passwordController, "رمز عبور"),
            const SizedBox(height: 12),
            _password(_confirmPasswordController, "تأیید رمز عبور",
                confirm: true),
            const SizedBox(height: 24),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        maxLength: maxLength,
        validator: validator,
        inputFormatters:
            keyboard == TextInputType.number
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
        style: const TextStyle(color: Colors.white),
        decoration: _decoration(label, icon),
      ),
    );
  }

  Widget _password(TextEditingController c, String label,
      {bool confirm = false}) {
    return TextFormField(
      controller: c,
      obscureText: !_showPassword,
      style: const TextStyle(color: Colors.white),
      validator: (v) {
        if (v == null || v.length < 8) {
          return "حداقل ۸ کاراکتر";
        }
        if (confirm && v != _passwordController.text) {
          return "رمزها یکسان نیستند";
        }
        return null;
      },
      decoration: _decoration(label, Icons.lock).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword
                ? Icons.visibility
                : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: () =>
              setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.lightBlue),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signup,
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
                    "ثبت‌نام",
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

  @override
  void dispose() {
    _codeMelliController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _diseaseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
