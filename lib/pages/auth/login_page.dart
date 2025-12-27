import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../routes/smart_route.dart';

import 'forgot_password_page.dart';
import 'select_user_type_page.dart';

import '../patient/patient_home_page.dart';
import '../doctor/doctor_dashboard_page.dart';
import '../admin/admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _codeMelliController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _isAdminMode = false; // ⭐ ADMIN MODE

  // ================= VALIDATION =================
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

  // ================= LOGIN =================
  Future<void> _login({required bool isAdmin}) async {
    if (_isLoading) return;

    // patient / doctor validation
    if (!isAdmin && !_formKey.currentState!.validate()) return;

    // admin only empty check
    if (isAdmin) {
      if (_codeMelliController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        _snack("نام کاربری و رمز عبور الزامی است", Colors.red);
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final res = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/login"),
            headers: const {"Content-Type": "application/json"},
            body: jsonEncode({
              "codeMelli": _codeMelliController.text.trim(),
              "password": _passwordController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await AuthService.saveToken(data["access_token"]);

        if (!mounted) return;

        switch (data["role"]) {
          case "patient":
            Navigator.pushReplacement(
              context,
              SmartRoute.go(const HomePage(), type: RouteType.patient),
            );
            break;

          case "doctor":
            Navigator.pushReplacement(
              context,
              SmartRoute.go(
                const DoctorDashboardPage(),
                type: RouteType.doctor,
              ),
            );
            break;

          case "admin":
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminDashboardPage(),
              ),
            );
            break;

          default:
            _snack("نقش کاربر نامعتبر است", Colors.red);
        }
      } else {
        _snack("نام کاربری یا رمز عبور اشتباه است", Colors.red);
      }
    } on SocketException {
      _snack("عدم اتصال به سرور", Colors.orange);
    } on TimeoutException {
      _snack("پاسخ سرور طول کشید", Colors.orange);
    } catch (_) {
      _snack("خطای غیرمنتظره", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  // ================= ADMIN DIALOG =================
  void _showAdminLoginDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2B33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "ورود مدیر سیستم",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "نام کاربری و رمز عبور را وارد کنید",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("لغو", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _login(isAdmin: true); // ⭐ ONLY HERE
            },
            child: const Text("ورود"),
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          setState(() => _isAdminMode = true);
                          _showAdminLoginDialog();
                        },
                        child: const CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.white12,
                          child: Icon(Icons.lock_outline,
                              size: 36, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        "ورود به حساب",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),

                      _field(
                        controller: _codeMelliController,
                        label:
                            _isAdminMode ? "نام کاربری" : "کد ملی",
                        icon: Icons.person_outline,
                        keyboard: _isAdminMode
                            ? TextInputType.text
                            : TextInputType.number,
                        formatter: _isAdminMode
                            ? null
                            : [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "این فیلد الزامی است";
                          }
                          if (!_isAdminMode &&
                              !_isValidNationalCode(v)) {
                            return "کد ملی نامعتبر است";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      _field(
                        controller: _passwordController,
                        label: "رمز عبور",
                        icon: Icons.lock_outline,
                        obscure: !_showPassword,
                        validator: (v) =>
                            v == null || v.length < 3
                                ? "رمز کوتاه است"
                                : null,
                        suffix: IconButton(
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
                      const SizedBox(height: 28),

                      // ⭐ BUTTON ONLY FOR PATIENT / DOCTOR
                      _loginButton(),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            SmartRoute.go(
                              const ForgotPasswordPage(),
                              type: RouteType.back,
                            ),
                          );
                        },
                        child: const Text(
                          "فراموشی رمز عبور",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            SmartRoute.go(
                              const SelectSignupTypePage(),
                              type: RouteType.patient,
                            ),
                          );
                        },
                        child: const Text(
                          "ثبت‌نام",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: _isLoading
            ? null
            : () => _login(isAdmin: false), // ⭐ NOT ADMIN
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF36D1DC), Color(0xFF5B86E5)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "ورود",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatter,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formatter,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeMelliController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
