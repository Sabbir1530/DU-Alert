import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/public_alert.dart';
import '../services/api_service.dart';

class PublicAlertProvider extends ChangeNotifier {
  final int _feedPageSize = 10;

  List<PublicAlert> _feed = [];
  List<PublicAlert> _myAlerts = [];
  List<PublicAlert> _allAlerts = [];
  bool _loading = false;
  bool _feedLoadingMore = false;
  bool _feedHasMore = true;
  int _feedPage = 1;
  String? _error;

  List<PublicAlert> get feed => _feed;
  List<PublicAlert> get myAlerts => _myAlerts;
  List<PublicAlert> get allAlerts => _allAlerts;
  bool get loading => _loading;
  bool get feedLoadingMore => _feedLoadingMore;
  bool get feedHasMore => _feedHasMore;
  String? get error => _error;

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  PublicAlert? alertById(String id) {
    try {
      return _feed.firstWhere((alert) => alert.id == id);
    } catch (_) {
      try {
        return _myAlerts.firstWhere((alert) => alert.id == id);
      } catch (_) {
        try {
          return _allAlerts.firstWhere((alert) => alert.id == id);
        } catch (_) {
          return null;
        }
      }
    }
  }

  void _upsertAlert(PublicAlert updated) {
    final feedIdx = _feed.indexWhere((a) => a.id == updated.id);
    if (feedIdx >= 0) {
      _feed[feedIdx] = updated;
    }

    final myIdx = _myAlerts.indexWhere((a) => a.id == updated.id);
    if (myIdx >= 0) {
      _myAlerts[myIdx] = updated;
    }

    final allIdx = _allAlerts.indexWhere((a) => a.id == updated.id);
    if (allIdx >= 0) {
      _allAlerts[allIdx] = updated;
    }
  }

  PublicAlert _copyAlertWithReaction(
    PublicAlert source, {
    required String? myReaction,
    required Map<String, int> summary,
  }) {
    final reactionCount = summary.values.fold<int>(0, (sum, n) => sum + n);
    return PublicAlert(
      id: source.id,
      title: source.title,
      category: source.category,
      description: source.description,
      createdBy: source.createdBy,
      anonymous: source.anonymous,
      approvalStatus: source.approvalStatus,
      rejectionReason: source.rejectionReason,
      visibility: source.visibility,
      createdAt: source.createdAt,
      media: source.media,
      creator: source.creator,
      reactionSummary: summary,
      reactionCount: reactionCount,
      commentCount: source.commentCount,
      myReaction: myReaction,
      comments: source.comments,
    );
  }

  PublicAlert _copyAlertWithComments(
    PublicAlert source, {
    required List<PublicAlertComment> comments,
  }) {
    return PublicAlert(
      id: source.id,
      title: source.title,
      category: source.category,
      description: source.description,
      createdBy: source.createdBy,
      anonymous: source.anonymous,
      approvalStatus: source.approvalStatus,
      rejectionReason: source.rejectionReason,
      visibility: source.visibility,
      createdAt: source.createdAt,
      media: source.media,
      creator: source.creator,
      reactionSummary: source.reactionSummary,
      reactionCount: source.reactionCount,
      commentCount: comments.length,
      myReaction: source.myReaction,
      comments: comments,
    );
  }

  Future<bool> create({
    required String title,
    required String category,
    required String description,
    bool anonymous = false,
    List<XFile>? mediaFiles,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      await ApiService.postMultipart(
        '/public-alerts',
        fields: {
          'title': title,
          'category': category,
          'description': description,
          'anonymous': anonymous.toString(),
          'visibility': 'PUBLIC',
        },
        files: mediaFiles,
      );
      _setLoading(false);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Connection error';
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchFeed({bool refresh = false}) async {
    if (refresh) {
      _feedPage = 1;
      _feedHasMore = true;
      _feed = [];
    }

    if (!_feedHasMore && !refresh) return;
    if (_feedLoadingMore) return;

    final isInitialRequest = _feedPage == 1;

    if (isInitialRequest) {
      _setLoading(true);
    } else {
      _feedLoadingMore = true;
      notifyListeners();
    }

    _error = null;

    try {
      final path = '/alerts/public?page=$_feedPage&limit=$_feedPageSize';
      final res = await ApiService.get(path);

      final incoming = (res['alerts'] as List? ?? const [])
          .map((j) => PublicAlert.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();

      if (isInitialRequest) {
        _feed = incoming;
      } else {
        _feed = [..._feed, ...incoming];
      }

      final pagination = res['pagination'] as Map<String, dynamic>?;
      if (pagination != null && pagination['has_more'] is bool) {
        _feedHasMore = pagination['has_more'] as bool;
      } else {
        _feedHasMore = incoming.length >= _feedPageSize;
      }

      if (_feedHasMore) {
        _feedPage += 1;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    }

    if (isInitialRequest) {
      _setLoading(false);
    } else {
      _feedLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreFeed() async {
    await fetchFeed(refresh: false);
  }

  Future<bool> reactToAlert(String alertId, String reactionType) async {
    _error = null;
    try {
      final res = await ApiService.post(
        '/alerts/$alertId/react',
        body: {'reaction_type': reactionType},
      );

      final summaryRaw =
          (res['reaction_summary'] as Map<String, dynamic>? ?? {});
      final summary = <String, int>{
        'like': (summaryRaw['like'] as num?)?.toInt() ?? 0,
        'important': (summaryRaw['important'] as num?)?.toInt() ?? 0,
        'safe':
            (summaryRaw['safe'] as num?)?.toInt() ??
            (summaryRaw['support'] as num?)?.toInt() ??
            0,
        'alerted':
            (summaryRaw['alerted'] as num?)?.toInt() ??
            (summaryRaw['concern'] as num?)?.toInt() ??
            0,
      };

      final current = alertById(alertId);
      if (current != null) {
        _upsertAlert(
          _copyAlertWithReaction(
            current,
            myReaction: res['my_reaction']?.toString(),
            summary: summary,
          ),
        );
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Connection error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeReaction(String alertId) async {
    _error = null;
    try {
      final res = await ApiService.delete('/alerts/$alertId/react');

      final summaryRaw =
          (res['reaction_summary'] as Map<String, dynamic>? ?? {});
      final summary = <String, int>{
        'like': (summaryRaw['like'] as num?)?.toInt() ?? 0,
        'important': (summaryRaw['important'] as num?)?.toInt() ?? 0,
        'safe': (summaryRaw['safe'] as num?)?.toInt() ?? 0,
        'alerted': (summaryRaw['alerted'] as num?)?.toInt() ?? 0,
      };

      final current = alertById(alertId);
      if (current != null) {
        _upsertAlert(
          _copyAlertWithReaction(current, myReaction: null, summary: summary),
        );
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Connection error';
      notifyListeners();
      return false;
    }
  }

  Future<List<PublicAlertComment>> fetchComments(
    String alertId, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await ApiService.get(
      '/alerts/$alertId/comments?page=$page&limit=$limit',
    );
    return (res['comments'] as List? ?? const [])
        .map(
          (item) => PublicAlertComment.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<bool> addCommentToAlert(String alertId, String content) async {
    _error = null;
    try {
      final res = await ApiService.post(
        '/alerts/$alertId/comments',
        body: {'content': content.trim()},
      );

      final current = alertById(alertId);
      if (current != null) {
        final commentJson = Map<String, dynamic>.from(res['comment'] as Map);
        final comment = PublicAlertComment.fromJson(commentJson);
        final comments = [...current.comments, comment];
        _upsertAlert(_copyAlertWithComments(current, comments: comments));
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Connection error';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment({
    required String alertId,
    required String commentId,
  }) async {
    _error = null;
    try {
      await ApiService.delete('/comments/$commentId');
      final current = alertById(alertId);
      if (current != null) {
        final comments = current.comments
            .where((comment) => comment.id != commentId)
            .toList();
        _upsertAlert(_copyAlertWithComments(current, comments: comments));
        notifyListeners();
      }
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Connection error';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchMy() async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/public-alerts/my');
      _myAlerts = (res['alerts'] as List)
          .map((j) => PublicAlert.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<PublicAlert?> fetchById(String id) async {
    _setLoading(true);
    try {
      final res = await ApiService.get('/public-alerts/$id');
      final alert = PublicAlert.fromJson(
        Map<String, dynamic>.from(res['alert'] as Map),
      );
      _upsertAlert(alert);
      _setLoading(false);
      return alert;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  Future<void> fetchAll({String? status}) async {
    _setLoading(true);
    try {
      final path = status != null
          ? '/public-alerts?approval_status=$status'
          : '/public-alerts';
      final res = await ApiService.get(path);
      _allAlerts = (res['alerts'] as List)
          .map((j) => PublicAlert.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> review(
    String id,
    String approvalStatus, {
    String? rejectionReason,
  }) async {
    try {
      await ApiService.patch(
        '/public-alerts/$id/review',
        body: {
          'approval_status': approvalStatus,
          if (rejectionReason != null) 'rejection_reason': rejectionReason,
        },
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
