import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import 'doctor_dashboard_page.dart';

class MoshakhasotDoctor extends StatefulWidget {
  const MoshakhasotDoctor({super.key});

  @override
  State<MoshakhasotDoctor> createState() => _MoshakhasotDoctorState();
}

class _MoshakhasotDoctorState extends State<MoshakhasotDoctor> {
  Map<String, dynamic>? _doctor;
  bool _loading = true;
  bool _editMode = false;

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  int? _selectedHospitalId;
  int? _selectedSpecialtyId;

  List<Map<String, dynamic>> _hospitals = [];
  List<Map<String, dynamic>> _specialties = [];

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ================= LOAD =================
  Future<void> _loadDoctor() async {
    setState(() => _loading = true);

    try {
      final token = await AuthService.getToken();

      final doctorRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/me"),
        headers: {"Authorization": "Bearer $token"},
      );

      final hospitalsRes =
          await http.get(Uri.parse("${ApiConfig.baseUrl}/hospitals"));

      if (doctorRes.statusCode == 200 &&
          hospitalsRes.statusCode == 200) {
        _doctor = jsonDecode(doctorRes.body);
        _hospitals =
            List<Map<String, dynamic>>.from(jsonDecode(hospitalsRes.body));

        // basic fields
        _fullNameCtrl.text = _doctor!['fullName'] ?? '';
        _phoneCtrl.text = _doctor!['phone'] ?? '';

        // ================= MAP hospital name -> id =================
        final hospitalName = _doctor!['hospital'];
        if (hospitalName != null &&
            hospitalName.toString().isNotEmpty) {
          final h = _hospitals.firstWhere(
            (x) => x['name'] == hospitalName,
            orElse: () => {},
          );

          if (h.isNotEmpty) {
            _selectedHospitalId = h['id'];

            // load specialties of this hospital
            await _loadSpecialties(_selectedHospitalId!);

            // ================= MAP specialty name -> id =================
            final specialtyName = _doctor!['specialty'];
            if (specialtyName != null &&
                specialtyName.toString().isNotEmpty) {
              final s = _specialties.firstWhere(
                (x) => x['title'] == specialtyName,
                orElse: () => {},
              );
              if (s.isNotEmpty) {
                _selectedSpecialtyId = s['id'];
              }
            }
          }
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadSpecialties(int hospitalId) async {
    final res = await http.get(
      Uri.parse(
          "${ApiConfig.baseUrl}/hospitals/$hospitalId/specialties"),
    );
    if (res.statusCode == 200) {
      _specialties =
          List<Map<String, dynamic>>.from(jsonDecode(res.body));
    }
  }

  // ================= SAVE =================
  Future<void> _save() async {
    final token = await AuthService.getToken();

    final res = await http.put(
      Uri.parse("${ApiConfig.baseUrl}/doctor/profile"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "fullName": _fullNameCtrl.text,
        "phone": _phoneCtrl.text,
        "hospitalId": _selectedHospitalId,
        "specialtyId": _selectedSpecialtyId,
      }),
    );

    if (res.statusCode == 200) {
      setState(() => _editMode = false);
      _loadDoctor();
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.25),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DoctorDashboardPage(),
              ),
            );
          },
        ),
        title: const Text(
          'مشخصات پزشک',
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
                    title: 'نام و نام خانوادگی',
                    controller: _fullNameCtrl,
                  ),
                  _infoCard(
                    title: 'شماره تماس',
                    controller: _phoneCtrl,
                    keyboard: TextInputType.phone,
                  ),

                  _dropdownCard(
                    title: 'بیمارستان',
                    value: _selectedHospitalId,
                    items: _hospitals,
                    labelKey: 'name',
                    onChanged: (v) async {
                      _selectedHospitalId = v;
                      _selectedSpecialtyId = null;
                      _specialties.clear();
                      if (v != null) await _loadSpecialties(v);
                      setState(() {});
                    },
                  ),

                  _dropdownCard(
                    title: 'تخصص',
                    value: _selectedSpecialtyId,
                    items: _specialties,
                    labelKey: 'title',
                    onChanged: (v) =>
                        setState(() => _selectedSpecialtyId = v),
                  ),

                  const Spacer(),
                  if (_editMode) _saveButton(),
                ],
              ),
            ),
    );
  }

  // ================= COMPONENTS =================
  Widget _header() => Column(
        children: const [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white24,
            child: Icon(Icons.medical_services,
                size: 44, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            'اطلاعات پزشک',
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
          leading:
              const Icon(Icons.edit, color: Colors.lightBlueAccent),
          title: Text(
            title,
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.bold),
          ),
          subtitle: _editMode
              ? TextField(
                  controller: controller,
                  keyboardType: keyboard,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      const InputDecoration(border: InputBorder.none),
                )
              : Text(
                  controller.text.isEmpty ? '—' : controller.text,
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      );

  Widget _dropdownCard({
    required String title,
    required int? value,
    required List<Map<String, dynamic>> items,
    required String labelKey,
    required ValueChanged<int?> onChanged,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: DropdownButtonFormField<int>(
          value: value,
          dropdownColor: const Color(0xFF203A43),
          decoration: InputDecoration(
            labelText: title,
            labelStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          items: items
              .map(
                (i) => DropdownMenuItem<int>(
                  value: i['id'],
                  child: Text(
                    i[labelKey],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
              .toList(),
          onChanged: _editMode ? onChanged : null,
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
