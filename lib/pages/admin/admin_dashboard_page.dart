import 'package:flutter/material.dart';
import '../../routes/smart_route.dart';
import '../../services/auth_service.dart';

import '../auth/login_page.dart';
import 'admin_hospitals_page.dart';
import 'admin_specialties_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  // ================= LOGOUT =================
  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text(
          'پنل مدیریت',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: "خروج",
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              context,
              title: 'مدیریت بیمارستان‌ها',
              icon: Icons.local_hospital,
              page: const AdminHospitalsPage(),
            ),
            const SizedBox(height: 16),
            _card(
              context,
              title: 'مدیریت تخصص‌ها',
              icon: Icons.medical_services,
              page: const AdminSpecialtiesPage(),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CONFIRM LOGOUT =================
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2B33),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "خروج از حساب",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "آیا می‌خواهید از پنل مدیریت خارج شوید؟",
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
              _logout(context);
            },
            child: const Text("خروج"),
          ),
        ],
      ),
    );
  }

  // ================= CARD =================
  Widget _card(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget page,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          SmartRoute.go(page, type: RouteType.admin),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.18),
              Colors.white.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 34, color: Colors.white),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
