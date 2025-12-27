import 'package:flutter/material.dart';

import '../../routes/smart_route.dart';
import 'patient_signup_page.dart';
import 'doctor_signup_page.dart';

class SelectSignupTypePage extends StatelessWidget {
  const SelectSignupTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCard(
                        context: context,
                        title: "ثبت‌نام بیمار",
                        subtitle: "دریافت خدمات درمانی",
                        icon: Icons.person,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            SmartRoute.go(
                              const SignupPage(),
                              type: RouteType.patient,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildCard(
                        context: context,
                        title: "ثبت‌نام پزشک",
                        subtitle: "دسترسی به پنل پزشکان",
                        icon: Icons.medical_services,
                        color: Colors.greenAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            SmartRoute.go(
                              const DoctorSignupPage(),
                              type: RouteType.doctor,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 8),
          const Icon(
            Icons.app_registration,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 10),
          const Text(
            "انتخاب نوع ثبت‌نام",
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

  // ---------- CARD ----------
  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}
