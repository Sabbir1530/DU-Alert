import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../services/api_service.dart';

class ComplaintProvider extends ChangeNotifier {
  List<Complaint> _myComplaints = [];
  List<Complaint> _allComplaints = [];
  Complaint? _selected;
  bool _loading = false;
  String? _error;

  List<Complaint> get myComplaints => _myComplaints;
  List<Complaint> get allComplaints => _allComplaints;
  Complaint? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  Future<bool> createComplaint({
    required String category,
    required String description,
    List<Map<String, String>>? complainants,
    List<Map<String, String>>? accused,
    List<File>? mediaFiles,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final fields = <String, String>{
        'category': category,
        'description': description,
      };
      if (complainants != null) {
        for (int i = 0; i < complainants.length; i++) {
          fields['complainants[$i]'] = jsonEncode(complainants[i]);
        }
      }
      if (accused != null) {
        for (int i = 0; i < accused.length; i++) {
          fields['accused[$i]'] = jsonEncode(accused[i]);
        }
      }

      await ApiService.postMultipart(
        '/complaints',
        fields: fields,
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

  Future<void> fetchMy() async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/complaints/my');
      _myComplaints = (res['complaints'] as List)
          .map((j) => Complaint.fromJson(j))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchAll({String? category, String? status}) async {
    _setLoading(true);
    try {
      final params = <String>[];
      if (category != null) params.add('category=$category');
      if (status != null) params.add('status=$status');
      final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await ApiService.get('/complaints$qs');
      _allComplaints = (res['complaints'] as List)
          .map((j) => Complaint.fromJson(j))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchById(String id) async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/complaints/$id');
      _selected = Complaint.fromJson(res['complaint']);
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      await ApiService.patch(
        '/complaints/$id/status',
        body: {'status': status},
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
