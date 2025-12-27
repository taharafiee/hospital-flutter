import 'package:flutter/material.dart';

import '../../services/prescription_service.dart';
import 'doctor_dashboard_page.dart';

class NoskheBimar extends StatefulWidget {
  const NoskheBimar({super.key});

  @override
  State<NoskheBimar> createState() => _NoskheBimarState();
}

class _NoskheBimarState extends State<NoskheBimar> {
  late Future<List<Map<String, dynamic>>> _futurePrescriptions;

  @override
  void initState() {
    super.initState();
    _futurePrescriptions = PrescriptionService.getDoctorPrescriptions();
  }

  void _reload() {
    setState(() {
      _futurePrescriptions = PrescriptionService.getDoctorPrescriptions();
    });
  }

  // ================= ADD PRESCRIPTION =================
  Future<void> _addPrescription(int visitId) async {
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ثبت نسخه پزشک'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'توضیحات نسخه',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ثبت'),
          ),
        ],
      ),
    );

    if (confirmed != true || controller.text.trim().isEmpty) return;

    await PrescriptionService.addPrescription(
      visitId: visitId,
      details: controller.text.trim(),
    );

    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.25),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DoctorDashboardPage()),
            );
          },
        ),
        title: const Text(
          'ویزیت و نسخه‌ها',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _futurePrescriptions,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'خطا در دریافت اطلاعات',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            final data = snapshot.data ?? [];

            if (data.isEmpty) {
              return const Center(
                child: Text(
                  'هیچ ویزیتی ثبت نشده',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final p = data[index];

                final int visitId = p['id']; // 🔑 خیلی مهم
                final String fullName = (p['fullName'] ?? '').toString();
                final String codeMelli = (p['codeMelli'] ?? '').toString();
                final String date = (p['date'] ?? '').toString();
                final String disease = (p['disease'] ?? '').toString();
                final String details = (p['details'] ?? '').toString();

                final bool hasPrescription = details.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            fullName.isNotEmpty
                                ? 'بیمار $fullName'
                                : 'بیمار $codeMelli',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          _badge(
                            hasPrescription ? 'ویزیت + نسخه' : 'ویزیت',
                            hasPrescription
                                ? Colors.purpleAccent
                                : Colors.lightBlueAccent,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      _infoRow('تاریخ', date),
                      _infoRow('بیماری', disease),

                      const SizedBox(height: 12),

                      if (hasPrescription)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            details,
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _addPrescription(visitId),
                            child: const Text('ثبت نسخه'),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white54),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
