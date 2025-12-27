import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class AdminHospitalSpecialtiesPage extends StatefulWidget {
  final int hospitalId;
  final String hospitalName;

  const AdminHospitalSpecialtiesPage({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
  });

  @override
  State<AdminHospitalSpecialtiesPage> createState() =>
      _AdminHospitalSpecialtiesPageState();
}

class _AdminHospitalSpecialtiesPageState
    extends State<AdminHospitalSpecialtiesPage> {
  bool _loading = true;

  List<Map<String, dynamic>> _linked = [];
  List<Map<String, dynamic>> _allSpecialties = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadLinkedSpecialties(),
      _loadAllSpecialties(),
    ]);
    setState(() => _loading = false);
  }

  // ================= LOAD LINKED =================
  Future<void> _loadLinkedSpecialties() async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse(
        "${ApiConfig.baseUrl}/admin/hospitals/${widget.hospitalId}/specialties",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      _linked = List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
  }

  // ================= LOAD ALL =================
  Future<void> _loadAllSpecialties() async {
    final token = await AuthService.getToken();
    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/admin/specialties"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      _allSpecialties =
          List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
  }

  // ================= ADD =================
  Future<void> _addSpecialty(int specialtyId) async {
    final token = await AuthService.getToken();

    final res = await http.post(
      Uri.parse(
        "${ApiConfig.baseUrl}/admin/hospitals/${widget.hospitalId}/specialties",
      ),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"specialtyId": specialtyId}),
    );

    if (res.statusCode == 200) {
      _snack("تخصص اضافه شد", Colors.green);
      _loadAll();
    } else {
      _snack("خطا در افزودن تخصص", Colors.red);
    }
  }

  // ================= DELETE =================
  void _confirmDelete(int sid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2B33),
        title: const Text("حذف تخصص",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "آیا از حذف این تخصص از بیمارستان مطمئن هستید؟",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("لغو", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              _deleteSpecialty(sid);
            },
            child: const Text("حذف"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSpecialty(int sid) async {
    final token = await AuthService.getToken();

    final res = await http.delete(
      Uri.parse(
        "${ApiConfig.baseUrl}/admin/hospitals/${widget.hospitalId}/specialties/$sid",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      _snack("تخصص حذف شد", Colors.orange);
      _loadAll();
    } else {
      _snack("خطا در حذف تخصص", Colors.red);
    }
  }

  // ================= ADD DIALOG =================
  void _openAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2B33),
        title: const Text(
          "افزودن تخصص به بیمارستان",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: _allSpecialties.map((s) {
              final already =
                  _linked.any((l) => l["id"] == s["id"]);
              if (already) return const SizedBox();

              return ListTile(
                title: Text(
                  s["title"],
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.add, color: Colors.greenAccent),
                onTap: () {
                  Navigator.pop(context);
                  _addSpecialty(s["id"]);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _snack(String t, Color c) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t), backgroundColor: c));
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "تخصص‌های ${widget.hospitalName}",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Colors.white),
                )
              : _linked.isEmpty
                  ? const Center(
                      child: Text(
                        "هیچ تخصصی متصل نشده",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _linked.length,
                      itemBuilder: (_, i) => _card(_linked[i]),
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
              color: Colors.white, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              s["title"],
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete,
                color: Colors.redAccent),
            onPressed: () => _confirmDelete(s["id"]),
          ),
        ],
      ),
    );
  }
}
