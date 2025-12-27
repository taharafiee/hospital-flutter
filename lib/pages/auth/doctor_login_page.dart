import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/login_service.dart';

import '../doctor/doctor_dashboard_page.dart';
import 'doctor_signup_page.dart';
import 'forgot_password_page.dart';
import 'login_page.dart';

class DoctorLoginPage extends StatefulWidget {
  const DoctorLoginPage({super.key});

  @override
  State<DoctorLoginPage> createState() => _DoctorLoginPageState();
}

class _DoctorLoginPageState extends State<DoctorLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeMelliController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  bool _isValidNationalCode(String code) {
    if (!RegExp(r'^\d{10}$').hasMatch(code)) return false;
    final check = int.parse(code[9]);
    var sum = 0;
    for (var i = 0; i < 9; i++) {
      sum += int.parse(code[i]) * (10 - i);
    }
    sum %= 11;
    return (sum < 2 && check == sum) || (sum >= 2 && check == 11 - sum);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await LoginService.login(
        codeMelli: _codeMelliController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await AuthService.saveToken(result['access_token']);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DoctorDashboardPage(),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('کد ملی یا رمز عبور اشتباه است'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeMelliController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ورود پزشک'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginPage(),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 32),
              const Text(
                'لطفاً وارد حساب خود شوید',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _codeMelliController,
                maxLength: 10,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'کد ملی',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'کد ملی را وارد کنید';
                  }
                  if (!_isValidNationalCode(v)) {
                    return 'کد ملی نامعتبر است';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'رمز عبور',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'رمز عبور را وارد کنید' : null,
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ورود'),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                child: const Text('فراموشی رمز عبور؟'),
              ),

              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DoctorSignupPage(),
                          ),
                        );
                      },
                child: const Text('ثبت‌نام'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
