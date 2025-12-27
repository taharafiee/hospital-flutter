import 'package:flutter/material.dart';

import '../../services/doctor_service.dart';
import '../../services/auth_service.dart';

import 'moshakhasot_doctor.dart';
import 'bimar.dart';
import 'noskhe_bimar.dart';

import '../auth/login_page.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  Map<String, dynamic>? _doctor;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDoctor();
  }

  Future<void> _loadDoctor() async {
    try {
      final data = await DoctorService.getProfile();
      if (!mounted) return;
      setState(() {
        _doctor = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: _appBar(context),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _header(),

            const SizedBox(height: 20),

            _logoutCard(context),

            const SizedBox(height: 20),

            _menuCard(
              title: 'بیماران نوبت‌دار',
              subtitle: 'بیمارانی که برای شما وقت رزرو کرده‌اند',
              icon: Icons.people_alt_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Bimar()),
                );
              },
            ),

            _menuCard(
              title: 'نسخه‌ها',
              subtitle: 'نسخه‌های ثبت‌شده برای بیماران',
              icon: Icons.description_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NoskheBimar()),
                );
              },
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ================= APP BAR =================
  AppBar _appBar(BuildContext context) => AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.25),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'داشبورد پزشک',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MoshakhasotDoctor(),
                ),
              );
            },
          ),
        ],
      );

  // ================= HEADER =================
  Widget _header() {
    if (_loading) {
      // Skeleton Header
      return Column(
        children: [
          const CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white24,
          ),
          const SizedBox(height: 12),
          Container(
            height: 18,
            width: 140,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 14,
            width: 90,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const CircleAvatar(
          radius: 44,
          backgroundColor: Colors.white24,
          child: Icon(
            Icons.medical_services,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _doctor?['fullName'] ?? 'پزشک',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _doctor?['specialty'] ?? '',
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  // ================= MENU CARD =================
  Widget _menuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.lightBlueAccent, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  // ================= LOGOUT CARD =================
  Widget _logoutCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.white),
        title: const Text(
          'خروج از حساب',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () async {
          await AuthService.logout();
          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        },
      ),
    );
  }
}
