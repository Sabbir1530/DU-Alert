import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  List<User> _users = [];
  Map<String, dynamic>? _analytics;
  bool _loading = false;
  String? _error;

  List<User> get users => _users;
  Map<String, dynamic>? get analytics => _analytics;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> fetchUsers({String? role}) async {
    _setLoading(true);
    try {
      final path = role != null ? '/admin/users?role=$role' : '/admin/users';
      final res = await ApiService.get(path);
      _users = (res['users'] as List).map((j) => User.fromJson(j)).toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> createProctor({
    required String fullName,
    required String email,
    required String phone,
    required String username,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await ApiService.post(
        '/admin/proctors',
        body: {
          'full_name': fullName,
          'university_email': email,
          'phone': phone,
          'username': username,
          'password': password,
        },
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

  Future<bool> deleteUser(String id) async {
    try {
      await ApiService.delete('/admin/users/$id');
      await fetchUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchAnalytics() async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/admin/analytics');
      _analytics = res['analytics'];
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }
}
