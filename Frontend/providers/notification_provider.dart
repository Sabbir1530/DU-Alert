import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  bool _loading = false;
  String? _error;
  Timer? _pollTimer;

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

  void startPolling({Duration interval = const Duration(seconds: 25)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => fetch());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> markRead(String id) async {
    try {
      await ApiService.patch('/notifications/$id/read', body: {});
      _notifications = _notifications
          .map(
            (n) => n.id == id
                ? AppNotification(
                    id: n.id,
                    title: n.title,
                    message: n.message,
                    type: n.type,
                    referenceType: n.referenceType,
                    referenceId: n.referenceId,
                    referenceSubId: n.referenceSubId,
                    isRead: true,
                    createdAt: n.createdAt,
                    data: n.data,
                  )
                : n,
          )
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    try {
      await ApiService.post('/notifications/mark-all-read', body: {});
      _notifications = _notifications
          .map(
            (n) => AppNotification(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              referenceType: n.referenceType,
              referenceId: n.referenceId,
              referenceSubId: n.referenceSubId,
              isRead: true,
              createdAt: n.createdAt,
              data: n.data,
            ),
          )
          .toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
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
