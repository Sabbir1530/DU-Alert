import 'dart:io';
import 'package:flutter/material.dart';
import '../models/public_alert.dart';
import '../services/api_service.dart';

class PublicAlertProvider extends ChangeNotifier {
  List<PublicAlert> _feed = [];
  List<PublicAlert> _myAlerts = [];
  List<PublicAlert> _allAlerts = [];
  bool _loading = false;
  String? _error;

  List<PublicAlert> get feed => _feed;
  List<PublicAlert> get myAlerts => _myAlerts;
  List<PublicAlert> get allAlerts => _allAlerts;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<bool> create({
    required String category,
    required String description,
    bool anonymous = false,
    List<File>? mediaFiles,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await ApiService.postMultipart(
        '/public-alerts',
        fields: {
          'category': category,
          'description': description,
          'anonymous': anonymous.toString(),
        },
        files: mediaFiles,
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

  Future<void> fetchFeed() async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/public-alerts/feed', auth: false);
      _feed = (res['alerts'] as List)
          .map((j) => PublicAlert.fromJson(j))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchMy() async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/public-alerts/my');
      _myAlerts = (res['alerts'] as List)
          .map((j) => PublicAlert.fromJson(j))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchAll({String? status}) async {
    _setLoading(true);
    try {
      final path = status != null
          ? '/public-alerts?approval_status=$status'
          : '/public-alerts';
      final res = await ApiService.get(path);
      _allAlerts = (res['alerts'] as List)
          .map((j) => PublicAlert.fromJson(j))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> review(String id, String approvalStatus) async {
    try {
      await ApiService.patch(
        '/public-alerts/$id/review',
        body: {'approval_status': approvalStatus},
      );
      await fetchAll();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
