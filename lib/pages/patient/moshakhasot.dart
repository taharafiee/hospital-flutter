import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../auth/verify_otp_page.dart';

class MoshakhasotPage extends StatefulWidget {
  const MoshakhasotPage({super.key});

  @override
  State<MoshakhasotPage> createState() => _MoshakhasotPageState();
}

class _MoshakhasotPageState extends State<MoshakhasotPage> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _editMode = false;

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMe();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      _user = jsonDecode(res.body);
      _fullNameCtrl.text = _user!['fullName'] ?? '';
      _phoneCtrl.text = _user!['phone'] ?? '';
      _ageCtrl.text = (_user!['age'] ?? '').toString();
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "fullName": _fullNameCtrl.text,
        "phone": _phoneCtrl.text,
        "age": int.tryParse(_ageCtrl.text),
      }),
    );

    if (res.statusCode == 200) {
      setState(() => _editMode = false);
      _loadMe();
    }
  }

  void _goToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VerifyOtpPage(
          fromProfile: true, // 🔥 کل ماجرا همین خطه
        ),
      ),
    );
  }

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
          'مشخصات کاربر',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _editMode ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 24),

                  _infoCard(
                    title: 'کد ملی',
                    value: _user!['codeMelli'],
                  ),
                  _editableCard(
                    title: 'نام و نام خانوادگی',
                    controller: _fullNameCtrl,
                  ),
                  _editableCard(
                    title: 'شماره تماس',
                    controller: _phoneCtrl,
                    keyboard: TextInputType.phone,
                  ),
                  _editableCard(
                    title: 'سن',
                    controller: _ageCtrl,
                    keyboard: TextInputType.number,
                  ),

                  const Spacer(),

                  if (_editMode) _saveButton(),

                  const SizedBox(height: 12),

                  // 🔐 CHANGE PASSWORD
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _goToChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Ink(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF37474F),
                              Color(0xFF263238),
                            ],
                          ),
                          borderRadius:
                              BorderRadius.all(Radius.circular(14)),
                        ),
                        child: const Center(
                          child: Text(
                            'تغییر رمز عبور',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _header() => Column(
        children: const [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 46, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            'اطلاعات حساب',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'مشخصات ثبت‌شده شما',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );

  Widget _infoCard({
    required String title,
    required String value,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: ListTile(
          leading: const Icon(Icons.info, color: Colors.lightBlueAccent),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );

  Widget _editableCard({
    required String title,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: ListTile(
          leading: const Icon(Icons.edit, color: Colors.lightBlueAccent),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: _editMode
              ? TextField(
                  controller: controller,
                  keyboardType: keyboard,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                )
              : Text(
                  controller.text.isEmpty ? '—' : controller.text,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 16),
                ),
        ),
      );

  Widget _saveButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _save,
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
            child: const Center(
              child: Text(
                'ذخیره تغییرات',
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
