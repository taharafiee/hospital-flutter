import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';

class NoskhePage extends StatefulWidget {
  const NoskhePage({super.key});

  @override
  State<NoskhePage> createState() => _NoskhePageState();
}

class _NoskhePageState extends State<NoskhePage> {
  List<Map<String, dynamic>> _visits = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'کاربر وارد نشده است';
          _isLoading = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/prescriptions"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        _visits = List<Map<String, dynamic>>.from(jsonDecode(res.body));
      } else {
        _errorMessage = 'خطا در دریافت اطلاعات';
      }
    } on SocketException {
      _errorMessage = 'عدم اتصال به سرور';
    } catch (_) {
      _errorMessage = 'خطای غیرمنتظره';
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.25),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'مراجعات من',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadVisits,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.lightBlueAccent),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_visits.isEmpty) {
      return const Center(
        child: Text(
          'هنوز ویزیتی ثبت نشده',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: _visits.length,
      itemBuilder: (_, i) => _visitCard(_visits[i]),
    );
  }

  Widget _visitCard(Map<String, dynamic> v) {
    final date = (v['prescriptionDate'] ?? '—').toString();
    final doctor = (v['doctorName'] ?? '—').toString();
    final hospital = (v['hospitalName'] ?? '—').toString();
    final disease = (v['disease'] ?? '—').toString();
    final details = (v['details'] ?? '').toString();

    final hasPrescription = details.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    hasPrescription
                        ? Icons.medication
                        : Icons.medical_services,
                    color: hasPrescription
                        ? Colors.greenAccent
                        : Colors.lightBlueAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hasPrescription ? 'ویزیت + نسخه' : 'ویزیت',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              _badge(
                hasPrescription ? 'نسخه ثبت شد' : 'در انتظار نسخه',
                hasPrescription
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _infoRow(Icons.calendar_today, 'تاریخ', date),
          _infoRow(Icons.person, 'پزشک', doctor),
          _infoRow(Icons.local_hospital, 'بیمارستان', hospital),

          const SizedBox(height: 12),

          _sectionTitle(
            icon: Icons.report_problem,
            title: 'مشکل / بیماری',
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(height: 6),
          Text(
            disease,
            style: const TextStyle(
              color: Colors.white,
              height: 1.5,
            ),
          ),

          if (hasPrescription) ...[
            const SizedBox(height: 16),
            _sectionTitle(
              icon: Icons.description,
              title: 'نسخه پزشک',
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.green.withOpacity(0.35),
                ),
              ),
              child: Text(
                details,
                style: const TextStyle(
                  color: Colors.white,
                  height: 1.6,
                  fontSize: 14.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(22),
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

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.lightBlueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
