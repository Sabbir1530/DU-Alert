import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;
  List<String> _departments = [];

  // Registration state held across steps
  Map<String, String> _registrationData = {};

  User? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  String get role => _user?.role ?? '';
  List<String> get departments => _departments;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Fetch departments ──
  Future<void> fetchDepartments() async {
    try {
      final res = await ApiService.get('/auth/departments', auth: false);
      _departments = List<String>.from(res['departments']);
      notifyListeners();
    } catch (_) {}
  }

  // ── Step 1: Register (sends OTP) ──
  Future<bool> register({
    required String fullName,
    required String department,
    required String registrationNumber,
    required String universityEmail,
    required String phone,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await ApiService.post(
        '/auth/register',
        body: {
          'full_name': fullName,
          'department': department,
          'registration_number': registrationNumber,
          'university_email': universityEmail,
          'phone': phone,
        },
        auth: false,
      );
      _registrationData = {
        'full_name': fullName,
        'department': department,
        'registration_number': registrationNumber,
        'university_email': universityEmail,
        'phone': phone,
      };
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  // ── Step 2: Verify OTP ──
  Future<bool> verifyOtp(String phoneOrEmail, String otpCode) async {
    _setLoading(true);
    _error = null;
    try {
      await ApiService.post(
        '/auth/verify-otp',
        body: {'phone_or_email': phoneOrEmail, 'otp_code': otpCode},
        auth: false,
      );
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  // ── Step 3: Complete registration ──
  Future<bool> completeRegistration(String username, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final body = {
        ..._registrationData,
        'username': username,
        'password': password,
      };
      final res = await ApiService.post(
        '/auth/complete-registration',
        body: body,
        auth: false,
      );
      await ApiService.saveToken(res['token']);
      _user = User.fromJson(res['user']);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  // ── Login ──
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final res = await ApiService.post(
        '/auth/login',
        body: {'username': username, 'password': password},
        auth: false,
      );
      await ApiService.saveToken(res['token']);
      _user = User.fromJson(res['user']);
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  // ── Load profile (auto-login) ──
  Future<bool> loadProfile() async {
    final token = await ApiService.getToken();
    if (token == null) return false;
    try {
      final res = await ApiService.get('/auth/profile');
      _user = User.fromJson(res['user']);
      notifyListeners();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  // ── Logout ──
  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }

  // ── Password reset ──
  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    _error = null;
    try {
      await ApiService.post(
        '/auth/request-password-reset',
        body: {'university_email': email},
        auth: false,
      );
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    _setLoading(true);
    _error = null;
    try {
      await ApiService.post(
        '/auth/reset-password',
        body: {
          'university_email': email,
          'otp_code': otp,
          'new_password': newPassword,
        },
        auth: false,
      );
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }
}
