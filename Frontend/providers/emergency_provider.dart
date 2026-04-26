import 'package:flutter/material.dart';
import '../models/emergency_alert.dart';
import '../services/api_service.dart';

class EmergencyProvider extends ChangeNotifier {
  List<EmergencyAlert> _alerts = [];
  List<EmergencyAlert> _myAlerts = [];
  bool _loading = false;
  String? _error;

  List<EmergencyAlert> get alerts => _alerts;
  List<EmergencyAlert> get myAlerts => _myAlerts;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<bool> sendSOS(double latitude, double longitude) async {
    _setLoading(true);
    _error = null;
    try {
      await ApiService.post(
        '/emergency',
        body: {'latitude': latitude, 'longitude': longitude},
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

  Future<void> fetchAll({String? status}) async {
    _setLoading(true);
    _error = null;
    try {
      final path = status != null ? '/emergency?status=$status' : '/emergency';
      final res = await ApiService.get(path);
      _alerts = (res['alerts'] as List)
          .map((j) => EmergencyAlert.fromJson(j))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchMy() async {
    _setLoading(true);
    _error = null;
    try {
      final res = await ApiService.get('/emergency/my');
      _myAlerts = (res['alerts'] as List)
          .map((j) => EmergencyAlert.fromJson(j))
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<EmergencyAlert?> fetchById(String id) async {
    try {
      final res = await ApiService.get('/emergency/$id');
      return EmergencyAlert.fromJson(res['alert'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateStatus(
    String id,
    String status, {
    double? responderLatitude,
    double? responderLongitude,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (responderLatitude != null) {
        body['responder_latitude'] = responderLatitude;
      }
      if (responderLongitude != null) {
        body['responder_longitude'] = responderLongitude;
      }

      await ApiService.patch('/emergency/$id', body: body);
      await fetchAll();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
