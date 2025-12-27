import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class AdminSpecialtiesPage extends StatefulWidget {
  const AdminSpecialtiesPage({super.key});

  @override
  State<AdminSpecialtiesPage> createState() => _AdminSpecialtiesPageState();
}

class _AdminSpecialtiesPageState extends State<AdminSpecialtiesPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _specialties = [];

  Map<String, dynamic>? _lastDeleted; // برای Undo

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  // ================= LOAD =================
  Future<void> _loadSpecialties() async {
    setState(() => _loading = true);

    try {
      final token = await AuthService.getToken();
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/specialties"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        setState(() {
          _specialties =
              List<Map<String, dynamic>>.from(jsonDecode(res.body));
          _loading = false;
        });
      } else {
        _toast("خطا در دریافت تخصص‌ها", error: true);
      }
    } catch (_) {
      _toast("ارتباط با سرور برقرار نشد", error: true);
    }
  }

  // ================= ADD =================
  Future<void> _addSpecialty(String title) async {
    try {
      final token = await AuthService.getToken();
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/admin/specialties"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"title": title}),
      );

      if (res.statusCode == 200) {
        Navigator.pop(context);
        _toast("تخصص اضافه شد ✅");
        _loadSpecialties();
      } else {
        _toast("خطا در افزودن تخصص", error: true);
      }
    } catch (_) {
      _toast("خطای ارتباط با سرور", error: true);
    }
  }

  // ================= DELETE + UNDO =================
  Future<void> _deleteSpecialty(Map<String, dynamic> s) async {
    _lastDeleted = s;

    setState(() {
      _specialties.removeWhere((e) => e["id"] == s["id"]);
    });

    _showUndoSnack();

    try {
      final token = await AuthService.getToken();
      await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/admin/specialties/${s["id"]}"),
        headers: {"Authorization": "Bearer $token"},
      );
    } catch (_) {
      _toast("خطا در حذف تخصص", error: true);
    }
  }

  void _undoDelete() async {
    if (_lastDeleted == null) return;

    final token = await AuthService.getToken();
    await http.post(
      Uri.parse("${ApiConfig.baseUrl}/admin/specialties"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"title": _lastDeleted!["title"]}),
    );

    _toast("حذف لغو شد 🔄");
    _lastDeleted = null;
    _loadSpecialties();
  }

  // ================= DIALOG ADD =================
  void _openAddDialog() {
    final ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2B33),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "افزودن تخصص",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "عنوان تخصص",
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("لغو", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) {
                _toast("عنوان تخصص الزامی است", error: true);
                return;
              }
              _addSpecialty(ctrl.text.trim());
            },
            child: const Text("ثبت"),
          ),
        ],
      ),
    );
  }

  // ================= GLASS UNDO SNACK =================
  void _showUndoSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "تخصص حذف شد",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: _undoDelete,
                child: const Text(
                  "UNDO",
                  style: TextStyle(color: Colors.cyanAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TOAST =================
  void _toast(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? Colors.redAccent : Colors.green,
        content: Text(text),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مدیریت تخصص‌ها",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Colors.white),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _specialties.length,
                  itemBuilder: (_, i) => _card(_specialties[i]),
                ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          const Icon(Icons.medical_services,
              color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              s["title"],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _deleteSpecialty(s),
          ),
        ],
      ),
    );
  }
}
