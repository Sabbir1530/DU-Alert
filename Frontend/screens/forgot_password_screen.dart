import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otp = TextEditingController();
  final _newPassword = TextEditingController();
  bool _otpSent = false;
  bool _otpVerified = false;

  void _sendOtp() async {
    try {
      await ApiService.post(
        '/auth/request-password-reset',
        body: {'university_email': _emailCtrl.text.trim()},
        auth: false,
      );
      if (!mounted) return;
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  void _verifyOtp() async {
    if (_otp.text.trim().length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP must be 6 digits')));
      return;
    }

    try {
      await ApiService.post(
        '/auth/verify-otp',
        body: {
          'phone_or_email': _emailCtrl.text.trim(),
          'otp_code': _otp.text.trim(),
        },
        auth: false,
      );
      if (!mounted) return;
      setState(() => _otpVerified = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP verified')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  void _resetPassword() async {
    try {
      await ApiService.post(
        '/auth/reset-password',
        body: {
          'university_email': _emailCtrl.text.trim(),
          'otp_code': _otp.text.trim(),
          'new_password': _newPassword.text,
        },
        auth: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password reset')));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Connection error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _emailCtrl,
                enabled: !_otpSent,
                decoration: const InputDecoration(
                  labelText: 'University Email',
                ),
              ),
              const SizedBox(height: 8),
              if (!_otpSent)
                ElevatedButton(
                  onPressed: _sendOtp,
                  child: const Text('Send OTP'),
                )
              else
                Column(
                  children: [
                    TextField(
                      controller: _otp,
                      enabled: !_otpVerified,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'OTP (6 digits)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_otpVerified)
                      ElevatedButton(
                        onPressed: _verifyOtp,
                        child: const Text('Verify OTP'),
                      )
                    else
                      Column(
                        children: [
                          TextField(
                            controller: _newPassword,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'New password',
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _resetPassword,
                            child: const Text('Reset Password'),
                          ),
                        ],
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
