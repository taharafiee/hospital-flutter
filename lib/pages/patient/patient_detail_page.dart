import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../doctor/prescription_form_page.dart';

class MoshakhasotBimar extends StatefulWidget {
  final String patientCodeMelli;

  const MoshakhasotBimar({
    super.key,
    required this.patientCodeMelli,
  });

  @override
  State<MoshakhasotBimar> createState() => _MoshakhasotBimarState();
}

class _MoshakhasotBimarState extends State<MoshakhasotBimar> {
  Map<String, dynamic>? _patient;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      final token = await AuthService.getToken();

      final res = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/doctor/patients/${widget.patientCodeMelli}",
        ),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          _patient = jsonDecode(res.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'اطلاعاتی برای این بیمار یافت نشد';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'خطا در ارتباط با سرور';
        _loading = false;
      });
    }
  }

  void _goToPrescription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrescriptionPage(
          patientCodeMelli: widget.patientCodeMelli,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.black.withOpacity(0.25),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'مشخصات بیمار',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    children: [
                      _header(),
                      const SizedBox(height: 24),

                      _infoCard('نام و نام خانوادگی', _patient!['fullName']),
                      _infoCard('سن', _patient!['age']),
                      _infoCard('شماره تماس', _patient!['phone']),
                      _infoCard('بیمارستان', _patient!['hospital']),

                      const SizedBox(height: 16),

                      _infoCard(
                        'بیماری اعلام‌شده',
                        _patient!['disease'],
                        icon: Icons.sick,
                      ),

                      _infoCard(
                        'توضیحات بیمار',
                        _patient!['description'],
                        icon: Icons.notes,
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _goToPrescription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Ink(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF1976D2),
                                  Color(0xFF42A5F5),
                                ],
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                            ),
                            child: const Center(
                              child: Text(
                                'ثبت نسخه',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _header() => Column(
        children: const [
          CircleAvatar(
            radius: 44,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 44, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            'اطلاعات بیمار',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'جزئیات نسخه و وضعیت بیمار',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );

  Widget _infoCard(String title, dynamic value,
      {IconData icon = Icons.info}) {
    return Container(
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
            color: Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          value == null || value.toString().isEmpty ? '—' : value.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
