import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../routes/smart_route.dart';
import 'login_page.dart';

class DoctorSignupPage extends StatefulWidget {
  const DoctorSignupPage({super.key});

  @override
  State<DoctorSignupPage> createState() => _DoctorSignupPageState();
}

class _DoctorSignupPageState extends State<DoctorSignupPage> {
  final _formKey = GlobalKey<FormState>();

  final _codeMelliController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  int? _selectedHospitalId;
  int? _selectedSpecialtyId;

  List<Map<String, dynamic>> _hospitals = [];
  List<Map<String, dynamic>> _specialties = [];

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

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

  Future<void> _fetchHospitals() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/hospitals"),
      );

      if (res.statusCode == 200) {
        setState(() {
          _hospitals =
              List<Map<String, dynamic>>.from(jsonDecode(res.body));
        });
      }
    } catch (_) {
      _showSnack("خطا در دریافت بیمارستان‌ها", Colors.red);
    }
  }

  Future<void> _fetchSpecialties(int hospitalId) async {
    setState(() {
      _specialties = [];
      _selectedSpecialtyId = null;
    });

    try {
      final res = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/hospitals/$hospitalId/specialties",
        ),
      );

      if (res.statusCode == 200) {
        setState(() {
          _specialties =
              List<Map<String, dynamic>>.from(jsonDecode(res.body));
        });
      }
    } catch (_) {
      _showSnack("خطا در دریافت تخصص‌ها", Colors.red);
    }
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedHospitalId == null || _selectedSpecialtyId == null) {
      _showSnack("بیمارستان و تخصص را انتخاب کنید", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    final body = jsonEncode({
      "codeMelli": _codeMelliController.text.trim(),
      "fullName": _fullNameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "hospitalId": _selectedHospitalId,
      "specialtyId": _selectedSpecialtyId,
      "password": _passwordController.text.trim(),
    });

    try {
      final response = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/doctor/signup"),
            headers: const {"Content-Type": "application/json"},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack("ثبت‌نام پزشک با موفقیت انجام شد", Colors.green);
        Navigator.pushReplacement(
          context,
          SmartRoute.go(const LoginPage(), type: RouteType.doctor),
        );
      } else {
        _showSnack("خطا در ثبت‌نام", Colors.red);
      }
    } on SocketException {
      _showSnack("عدم اتصال به سرور", Colors.orange);
    } on TimeoutException {
      _showSnack("پاسخ سرور طول کشید", Colors.orange);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          const Icon(Icons.medical_services, color: Colors.white, size: 54),
          const SizedBox(height: 8),
          const Text(
            "ثبت‌نام پزشک",
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

  Widget _buildForm() {
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
            _field(
              _codeMelliController,
              "کد ملی",
              Icons.credit_card,
              keyboard: TextInputType.number,
              validator: (v) =>
                  v == null || !_isValidNationalCode(v)
                      ? "کد ملی نامعتبر است"
                      : null,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 14),
            _field(_fullNameController, "نام و نام خانوادگی", Icons.person),
            const SizedBox(height: 14),
            _field(
              _phoneController,
              "شماره موبایل",
              Icons.phone,
              keyboard: TextInputType.phone,
              validator: (v) =>
                  v == null || v.length != 11
                      ? "شماره موبایل باید ۱۱ رقم باشد"
                      : null,
              formatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
            ),
            const SizedBox(height: 14),
            _dropdownHospital(),
            const SizedBox(height: 14),
            _dropdownSpecialty(),
            const SizedBox(height: 14),
            _passwordField(),
            const SizedBox(height: 24),
            _submitButton(),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      inputFormatters: formatters,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
    );
  }

  Widget _dropdownHospital() {
    return DropdownButtonFormField<int>(
      value: _selectedHospitalId,
      dropdownColor: const Color(0xFF203A43),
      decoration: _inputDecoration("بیمارستان", Icons.local_hospital),
      items: _hospitals
          .map(
            (h) => DropdownMenuItem<int>(
              value: h['id'],
              child: Text(
                h['name'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        setState(() => _selectedHospitalId = v);
        if (v != null) _fetchSpecialties(v);
      },
      validator: (v) => v == null ? "بیمارستان را انتخاب کنید" : null,
    );
  }

  Widget _dropdownSpecialty() {
    return DropdownButtonFormField<int>(
      value: _selectedSpecialtyId,
      dropdownColor: const Color(0xFF203A43),
      decoration: _inputDecoration("تخصص", Icons.badge),
      items: _specialties
          .map(
            (s) => DropdownMenuItem<int>(
              value: s['id'],
              child: Text(
                s['title'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedSpecialtyId = v),
      validator: (v) => v == null ? "تخصص را انتخاب کنید" : null,
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      validator: (v) =>
          v == null || v.length < 8 ? "رمز حداقل ۸ کاراکتر باشد" : null,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration("رمز عبور", Icons.lock).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.white70,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
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

  InputDecoration _inputDecoration(String label, IconData icon) {
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

  @override
  void dispose() {
    _codeMelliController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
