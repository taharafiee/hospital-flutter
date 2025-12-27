import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';

import '../auth/login_page.dart';
import '../doctor/doctors_list_page.dart';
import 'patient_profile_menu_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _hospitals = [];

  final Map<int, List<Map<String, dynamic>>> _specialties = {};
  final Set<int> _expandedHospitals = {};

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  Future<void> _loadHospitals() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final res =
          await http.get(Uri.parse("${ApiConfig.baseUrl}/hospitals"));

      if (res.statusCode == 200) {
        _hospitals =
            List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSpecialties(int hospitalId) async {
    if (_specialties.containsKey(hospitalId)) return;

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/hospitals/$hospitalId/specialties"),
    );

    if (res.statusCode == 200) {
      _specialties[hospitalId] =
          List<Map<String, dynamic>>.from(jsonDecode(res.body));
      setState(() {});
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildWelcome(),
                const SizedBox(height: 24),
                _buildSearchCard(),
                const SizedBox(height: 20),
                Expanded(child: _buildHospitalList()),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.black.withOpacity(0.25),
      title: const Text(
        'Hospital App',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PorofilLogin(),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildWelcome() {
    return Column(
      children: const [
        Text(
          'به اپلیکیشن بیمارستان خوش آمدید',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'بیمارستان و تخصص مورد نظر خود را پیدا کنید',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          TextField(
            controller: _locationController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'منطقه',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon:
                  const Icon(Icons.location_on, color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Colors.lightBlue),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _gradientButton(
                  text: 'جستجو',
                  onTap: _loadHospitals,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _gradientButton(
                  text: 'پاک کردن',
                  colors: const [Colors.grey, Colors.blueGrey],
                  onTap: () {
                    _locationController.clear();
                    _loadHospitals();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalList() {
    if (_hospitals.isEmpty && !_isLoading) {
      return const Center(
        child: Text(
          'بیمارستانی یافت نشد',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: _hospitals.length,
      itemBuilder: (_, i) {
        final h = _hospitals[i];
        final id = h['id'];
        final isExpanded = _expandedHospitals.contains(id);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    h['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    h['location'],
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white54,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DoctorsPage(hospitalId: id),
                      ),
                    );
                  },
                ),
                InkWell(
                  onTap: () async {
                    if (isExpanded) {
                      setState(() => _expandedHospitals.remove(id));
                    } else {
                      await _loadSpecialties(id);
                      setState(() => _expandedHospitals.add(id));
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.lightBlueAccent,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'تخصص‌های موجود',
                        style: TextStyle(
                          color: Colors.lightBlueAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildSpecialtyChips(id),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecialtyChips(int hospitalId) {
    final list = _specialties[hospitalId];

    if (list == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return const Text(
        'تخصصی ثبت نشده',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: list.map((s) {
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.lightBlueAccent.withOpacity(0.8),
            ),
          ),
          child: Text(
            s['title'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _gradientButton({
    required String text,
    required VoidCallback onTap,
    List<Color> colors = const [
      Color(0xFF1976D2),
      Color(0xFF42A5F5),
    ],
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
