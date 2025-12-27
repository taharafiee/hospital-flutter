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

  void _log(String msg) {
    log('[OTP] $msg');
    debugPrint('[OTP] $msg');
  }

  @override
  void initState() {
    super.initState();
    _log('Page opened | fromProfile=${widget.fromProfile}');
    _startTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.fromProfile && !_sentOnce) {
        _log('AUTO SEND OTP');
        _sendOtp(force: true);
      }
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

  // ================= SEND / RESEND =================
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

      final body =
          widget.fromProfile ? {} : {'codeMelli': widget.codeMelli};

      _log('SEND OTP → POST $url');

      final res = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      _log('STATUS: ${res.statusCode}');
      if (res.statusCode == 200) {
        for (final c in _controllers) c.clear();
        _focusNodes.first.requestFocus();
        _startTimer();
        _snack('کد تأیید ارسال شد');
      } else {
        _snack('ارسال کد ناموفق بود');
      }
    } catch (e) {
      _log('ERROR SEND OTP: $e');
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

      _log('VERIFY → POST $url');

      final res = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      _log('STATUS: ${res.statusCode}');
      if (res.statusCode == 200) {
        final resetToken = jsonDecode(res.body)['reset_token'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ResetPasswordPage(resetToken: resetToken),
          ),
        );
      } else {
        _snack('کد وارد شده نامعتبر است');
      }
    } catch (e) {
      _log('ERROR VERIFY: $e');
      _snack('خطا در ارتباط با سرور');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
      resizeToAvoidBottomInset: true,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      _header(),
                      const SizedBox(height: 32),
                      _glassCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _header() => Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.05),
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            onEnd: () => setState(() {}),
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFF1976D2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.8),
                    blurRadius: 50,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.sms_rounded,
                  color: Colors.white, size: 46),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'تأیید کد پیامک',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'کد ۶ رقمی ارسال‌شده را وارد کنید',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 14),
          _timerRing(),
        ],
      );

  Widget _timerRing() {
    final progress = _secondsLeft / 120;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(
              Color(0xFF64B5F6),
            ),
          ),
          Text(
            _timerText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Row(
                  children: List.generate(
                    6,
                    (i) => Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: _otpBox(i),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
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
                        borderRadius:
                            BorderRadius.all(Radius.circular(16)),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                'تأیید کد',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _canResend ? () => _sendOtp() : null,
                  child: const Text('ارسال مجدد کد'),
                ),
              ],
            ),
          ),
        ),
      );

  // ================= OTP BOX =================
  Widget _otpBox(int index) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _focusNodes[index].hasFocus
                  ? Colors.blueAccent.withOpacity(0.6)
                  : Colors.transparent,
              blurRadius: 12,
            ),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 1,
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
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white.withOpacity(0.10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) {
              if (v.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              }
            },
          ),
        ),
      );
}
