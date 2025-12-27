import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'admin_hospital_specialties_page.dart';

class AdminHospitalsPage extends StatefulWidget {
  const AdminHospitalsPage({super.key});

  @override
  State<AdminHospitalsPage> createState() => _AdminHospitalsPageState();
}

class _AdminHospitalsPageState extends State<AdminHospitalsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  // ================= LOAD =================
  Future<void> _loadHospitals() async {
    setState(() => _loading = true);
    try {
      final token = await AuthService.getToken();
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/hospitals"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        _hospitals =
            List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= ADD / EDIT =================
  Future<void> _saveHospital({
    int? id,
    required String name,
    required String location,
  }) async {
    final token = await AuthService.getToken();

    final request = http.Request(
      id == null ? "POST" : "PUT",
      Uri.parse(
        id == null
            ? "${ApiConfig.baseUrl}/admin/hospitals"
            : "${ApiConfig.baseUrl}/admin/hospitals/$id",
      ),
    );

    request.headers.addAll({
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    });

    request.body = jsonEncode({
      "name": name,
      "location": location,
    });

    final res = await http.Response.fromStream(await request.send());

    if (res.statusCode == 200) {
      Navigator.pop(context);
      _toast(id == null
          ? "بیمارستان اضافه شد ✅"
          : "بیمارستان ویرایش شد ✏️");
      _loadHospitals();
    } else {
      _toast("خطا در ذخیره اطلاعات", error: true);
    }
  }

  // ================= DELETE =================
  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2B33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "حذف بیمارستان",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "آیا از حذف این بیمارستان مطمئن هستید؟",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("لغو", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteHospital(id);
            },
            child: const Text("حذف"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHospital(int id) async {
    final token = await AuthService.getToken();
    final res = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}/admin/hospitals/$id"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      _toast("بیمارستان حذف شد 🗑");
      _loadHospitals();
    } else {
      _toast("خطا در حذف بیمارستان", error: true);
    }
  }

  // ================= DIALOG =================
  void _openDialog({Map<String, dynamic>? hospital}) {
    final nameCtrl =
        TextEditingController(text: hospital?["name"] ?? "");
    final locCtrl =
        TextEditingController(text: hospital?["location"] ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2B33),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          hospital == null ? "افزودن بیمارستان" : "ویرایش بیمارستان",
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(nameCtrl, "نام بیمارستان"),
            const SizedBox(height: 12),
            _field(locCtrl, "شهر"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("لغو", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => _saveHospital(
              id: hospital?["id"],
              name: nameCtrl.text.trim(),
              location: locCtrl.text.trim(),
            ),
            child: const Text("ذخیره"),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }

  void _toast(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "مدیریت بیمارستان‌ها",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDialog(),
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
                  itemCount: _hospitals.length,
                  itemBuilder: (_, i) => _card(_hospitals[i]),
                ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> h) {
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
          const Icon(Icons.local_hospital,
              color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h["name"],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  h["location"],
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "مدیریت تخصص‌ها",
            icon: const Icon(Icons.account_tree,
                color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminHospitalSpecialtiesPage(
                    hospitalId: h["id"],
                    hospitalName: h["name"],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white70),
            onPressed: () => _openDialog(hospital: h),
          ),
          IconButton(
            icon:
                const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _confirmDelete(h["id"]),
          ),
        ],
      ),
    );
  }
}
