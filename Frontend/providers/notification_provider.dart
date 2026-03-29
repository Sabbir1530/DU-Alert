import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<void> fetch() async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/notifications');
      _notifications = (res['notifications'] as List)
          .map((j) => AppNotification.fromJson(j))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> createAnnouncement(
    String title,
    String message,
    String targetRole,
  ) async {
    try {
      await ApiService.post(
        '/notifications',
        body: {'title': title, 'message': message, 'target_role': targetRole},
      );
      await fetch();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
