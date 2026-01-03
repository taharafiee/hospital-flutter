import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import 'reset_password_page.dart';

class VerifyOtpPage extends StatefulWidget {
  final String? codeMelli;
  final bool fromProfile;

  const VerifyOtpPage({
    super.key,
    this.codeMelli,
    this.fromProfile = false,
  });

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _canResend = false;
  bool _sentOnce = false;

  Timer? _timer;
  int _secondsLeft = 120;

  @override
  void initState() {
    super.initState();

    // 🔥 خیلی مهم: روی focus تغییرات رو repaint کن
    for (final f in _focusNodes) {
      f.addListener(() => setState(() {}));
    }

    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.fromProfile && !_sentOnce) {
        _sendOtp(force: true);
      }
      _focusNodes.first.requestFocus();
    });
  }

  // ================= TIMER =================
  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 120;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() {
          _secondsLeft = 0;
          _canResend = true;
        });
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerText =>
      '${(_secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_secondsLeft % 60).toString().padLeft(2, '0')}';

  String get _otp => _controllers.map((c) => c.text).join();

  // ================= SEND OTP =================
  Future<void> _sendOtp({bool force = false}) async {
    if (!force && !_canResend) return;
    _sentOnce = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final url = widget.fromProfile
          ? '${ApiConfig.baseUrl}/forgot-password/me'
          : '${ApiConfig.baseUrl}/forgot-password';

      final headers = {
        'Content-Type': 'application/json',
        if (widget.fromProfile && token != null)
          'Authorization': 'Bearer $token',
      };

      final body = widget.fromProfile ? {} : {'codeMelli': widget.codeMelli};

      final res = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        for (final c in _controllers) c.clear();
        _focusNodes.first.requestFocus();
        _startTimer();
        _snack('کد ارسال شد');
      } else {
        _snack('ارسال کد ناموفق بود');
      }
    } catch (_) {
      _snack('خطا در ارتباط با سرور');
    }
  }

  // ================= VERIFY =================
  Future<void> _submit() async {
    if (_otp.length != 6) {
      _snack('کد ۶ رقمی را کامل وارد کنید');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final url = widget.fromProfile
          ? '${ApiConfig.baseUrl}/verify-forgot-code/me'
          : '${ApiConfig.baseUrl}/verify-forgot-code';

      final headers = {
        'Content-Type': 'application/json',
        if (widget.fromProfile && token != null)
          'Authorization': 'Bearer $token',
      };

      final body = widget.fromProfile
          ? {'otp': _otp}
          : {'codeMelli': widget.codeMelli, 'otp': _otp};

      final res = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        final resetToken = jsonDecode(res.body)['reset_token'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(resetToken: resetToken),
          ),
        );
      } else {
        _snack('کد نامعتبر است');
      }
    } catch (_) {
      _snack('خطا در ارتباط با سرور');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _glassCard(),
            ),
          ),
        ),
      ),
    );
  }

  // ================= GLASS CARD =================
  Widget _glassCard() => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'کد تأیید',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: List.generate(
                    6,
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _otpBox(i),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
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
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'تأیید',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _canResend ? _sendOtp : null,
                  child: Text(
                    _canResend ? 'ارسال مجدد' : _timerText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  // ================= OTP BOX =================
  Widget _otpBox(int index) => Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focusNodes[index].hasFocus
                ? Colors.lightBlueAccent
                : Colors.white24,
            width: 2,
          ),
        ),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          maxLength: 1,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
          onChanged: (v) {
            setState(() {});
            if (v.isNotEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            }
            if (v.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      );
}
