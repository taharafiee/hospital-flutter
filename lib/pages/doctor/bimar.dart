import 'package:flutter/material.dart';

import '../../services/doctor_service.dart';
import '../patient/patient_detail_page.dart';
import 'doctor_dashboard_page.dart';

class Bimar extends StatefulWidget {
  const Bimar({super.key});

  @override
  State<Bimar> createState() => _BimarState();
}

class _BimarState extends State<Bimar> {
  late Future<List<dynamic>> _futureAppointments;

  @override
  void initState() {
    super.initState();
    _futureAppointments = DoctorService.getAppointments();
  }

  // ✅ فقط از details می‌خونیم
  bool _isNotVisited(dynamic a) {
    final details = (a['details'] ?? '').toString().trim();
    return details.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text(
          'بیماران نوبت‌دار',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.25),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: _buildBackButton(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<dynamic>>(
          future: _futureAppointments,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'خطا در دریافت بیماران',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final allAppointments = snapshot.data ?? [];

            // 🔥 فقط بیمارایی که details خالیه
            final pendingAppointments =
                allAppointments.where(_isNotVisited).toList();

            if (pendingAppointments.isEmpty) {
              return const Center(
                child: Text(
                  'بیماری در انتظار ویزیت وجود ندارد',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              itemCount: pendingAppointments.length,
              itemBuilder: (context, index) {
                final a = pendingAppointments[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      a['fullName'] ?? 'بدون نام',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📞 ${a['phone']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '🗓 ${a['date']} | ⏰ ${a['time']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    trailing: _waitingBadge(),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MoshakhasotBimar(
                            patientCodeMelli: a['codeMelli'],
                          ),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          _futureAppointments =
                              DoctorService.getAppointments();
                        });
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // 🟠 همیشه «در انتظار ویزیت»
  Widget _waitingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange),
      ),
      child: const Text(
        'در انتظار ویزیت',
        style: TextStyle(
          color: Colors.orangeAccent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const DoctorDashboardPage(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: const Text(
              'بازگشت',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
          ),
        ),
      ),
    );
  }
}
