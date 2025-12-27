import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';

class DoctorsPage extends StatefulWidget {
  final int hospitalId;

  const DoctorsPage({
    super.key,
    required this.hospitalId,
  });

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _loadDoctors();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
  }

  // ================= LOAD DOCTORS =================
  Future<void> _loadDoctors() async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/hospitals/${widget.hospitalId}/doctors",
        ),
      );

      if (res.statusCode == 200) {
        setState(() {
          _doctors =
              List<Map<String, dynamic>>.from(jsonDecode(res.body));
          _isLoading = false;
        });
      } else {
        _setError('خطا در دریافت لیست پزشکان');
      }
    } on SocketException {
      _setError('عدم اتصال به سرور');
    } catch (_) {
      _setError('خطای غیرمنتظره');
    }
  }

  void _setError(String msg) {
    setState(() {
      _errorMessage = msg;
      _isLoading = false;
    });
  }

  // ================= BOOK APPOINTMENT =================
  Future<void> _bookAppointment(Map<String, dynamic> doctor) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      _showSnack('ابتدا باید به عنوان بیمار وارد شوید', Colors.orange);
      return;
    }

    final diseaseController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ثبت درخواست ویزیت'),
        content: StatefulBuilder(
          builder: (context, setLocalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1️⃣ بیماری
                TextField(
                  controller: diseaseController,
                  decoration: const InputDecoration(
                    labelText: 'مشکل / بیماری',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // 2️⃣ تاریخ
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black26),
                  ),
                  title: Text(
                    selectedDate == null
                        ? 'انتخاب تاریخ'
                        : 'تاریخ: ${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 60),
                      ),
                    );
                    if (date != null) {
                      setLocalState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 10),

                // 3️⃣ ساعت
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black26),
                  ),
                  title: Text(
                    selectedTime == null
                        ? 'انتخاب ساعت'
                        : 'ساعت: ${selectedTime!.format(context)}',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setLocalState(() => selectedTime = time);
                    }
                  },
                ),
              ],
            );
          },
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

    if (confirmed != true) {
      diseaseController.dispose();
      return;
    }

    if (diseaseController.text.trim().isEmpty ||
        selectedDate == null ||
        selectedTime == null) {
      _showSnack('لطفاً مشکل، تاریخ و ساعت را کامل وارد کنید', Colors.red);
      diseaseController.dispose();
      return;
    }

    final appointmentDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/appointments"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "doctorCodeMelli": doctor['codeMelli'],
          "disease": diseaseController.text.trim(),
          "appointmentDate": appointmentDateTime.toIso8601String(),
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showSnack('درخواست ویزیت با موفقیت ثبت شد', Colors.green);
      } else {
        final body = jsonDecode(res.body);
        _showSnack(body['detail'] ?? 'خطا در ثبت درخواست', Colors.red);
      }
    } catch (_) {
      _showSnack('مشکل در ارتباط با سرور', Colors.red);
    } finally {
      diseaseController.dispose();
    }
  }

  void _showSnack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.25),
        title: const Text(
          'انتخاب پزشک',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    if (_doctors.isEmpty) {
      return const Center(
        child: Text(
          'هیچ پزشکی برای این بیمارستان یافت نشد',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _doctors.length,
      itemBuilder: (_, i) => _doctorCard(_doctors[i]),
    );
  }

  Widget _doctorCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white.withOpacity(0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        title: Text(
          doctor['fullName'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'تخصص: ${doctor['specialty']}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: () => _bookAppointment(doctor),
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Text(
                'ثبت درخواست',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
