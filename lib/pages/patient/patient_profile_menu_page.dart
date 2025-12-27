import 'package:flutter/material.dart';

import '../../routes/smart_route.dart';
import 'moshakhasot.dart';
import 'noskhe.dart';
import '../auth/verify_otp_page.dart';

class PorofilLogin extends StatelessWidget {
  const PorofilLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.25),
        title: const Text(
          'پروفایل کاربری',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 24),

            // -------- مشخصات --------
            _card(
              title: 'مشخصات',
              icon: Icons.person,
              onTap: () {
                Navigator.push(
                  context,
                  SmartRoute.go(
                    const MoshakhasotPage(),
                    type: RouteType.patient,
                  ),
                );
              },
            ),

            // -------- نسخه‌ها --------
            _card(
              title: 'وضعیت نسخه',
              icon: Icons.description,
              onTap: () {
                Navigator.push(
                  context,
                  SmartRoute.go(
                    const NoskhePage(),
                    type: RouteType.patient,
                  ),
                );
              },
            ),

            // -------- تغییر رمز عبور (✔ درست) --------
            _card(
              title: 'تغییر رمز عبور',
              icon: Icons.lock,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('تغییر رمز عبور'),
                    content: const Text(
                      'برای تغییر رمز عبور، یک کد تأیید به شماره ثبت‌شده شما ارسال می‌شود. آیا ادامه می‌دهید؟',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('انصراف'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('ادامه'),
                      ),
                    ],
                  ),
                );

                if (ok != true) return;

                // 🔥🔥 این خط مشکل رو حل می‌کنه
                Navigator.push(
                  context,
                  SmartRoute.go(
                    const VerifyOtpPage(
                      fromProfile: true, // 👈 خیلی مهم
                    ),
                    type: RouteType.patient,
                  ),
                );
              },
            ),

            const Spacer(),
            _back(context),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() => Column(
        children: const [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 46, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            'حساب کاربری',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'مدیریت اطلاعات و تنظیمات',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );

  // ================= CARD =================
  Widget _card({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.lightBlueAccent),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white54,
            size: 16,
          ),
          onTap: onTap,
        ),
      );

  // ================= BACK BUTTON =================
  Widget _back(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
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
                'بازگشت',
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
