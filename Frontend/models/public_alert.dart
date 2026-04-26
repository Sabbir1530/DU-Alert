class PublicAlertComment {
  final String id;
  final String alertId;
  final String userId;
  final String content;
  final String createdAt;
  final Map<String, dynamic>? user;

  PublicAlertComment({
    required this.id,
    required this.alertId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.user,
  });

  factory PublicAlertComment.fromJson(Map<String, dynamic> json) {
    return PublicAlertComment(
      id: json['id']?.toString() ?? '',
      alertId: json['alert_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      user: json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : null,
    );
  }
}

class PublicAlert {
  final String id;
  final String title;
  final String category;
  final String description;
  final String createdBy;
  final bool anonymous;
  final String approvalStatus;
  final String? rejectionReason;
  final String visibility;
  final String createdAt;
  final List<Map<String, dynamic>> media;
  final Map<String, dynamic>? creator;
  final Map<String, int> reactionSummary;
  final int reactionCount;
  final int commentCount;
  final String? myReaction;
  final List<PublicAlertComment> comments;

  PublicAlert({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.createdBy,
    required this.anonymous,
    required this.approvalStatus,
    this.rejectionReason,
    required this.visibility,
    required this.createdAt,
    this.media = const [],
    this.creator,
    this.reactionSummary = const {
      'like': 0,
      'important': 0,
      'safe': 0,
      'alerted': 0,
    },
    this.reactionCount = 0,
    this.commentCount = 0,
    this.myReaction,
    this.comments = const [],
  });

  factory PublicAlert.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['reaction_summary'] as Map<String, dynamic>?;
    final parsedSummary = <String, int>{
      'like': 0,
      'important': 0,
      'safe': 0,
      'alerted': 0,
    };
    if (rawSummary != null) {
      final keyMap = <String, String>{
        'like': 'like',
        'important': 'important',
        'safe': 'safe',
        'alerted': 'alerted',
        'support': 'safe',
        'concern': 'alerted',
      };
      rawSummary.forEach((key, value) {
        final mapped = keyMap[key.toLowerCase()];
        if (mapped != null && value is num) {
          parsedSummary[mapped] = (parsedSummary[mapped] ?? 0) + value.toInt();
        }
      });
    }

    final media = (json['media'] as List? ?? const []).map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      final fileUrl =
          map['file_url']?.toString() ?? map['url']?.toString() ?? '';
      final fileType =
          map['file_type']?.toString() ?? map['type']?.toString() ?? 'file';
      return {
        ...map,
        'file_url': fileUrl,
        'url': fileUrl,
        'file_type': fileType,
        'type': fileType,
      };
    }).toList();

    final title = (json['title']?.toString() ?? '').trim();
    final category = json['category']?.toString() ?? '';

    return PublicAlert(
      id: json['id']?.toString() ?? '',
      title: title.isNotEmpty ? title : category,
      category: category,
      description: json['description']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      anonymous: json['anonymous'] ?? false,
      approvalStatus: json['approval_status']?.toString() ?? 'Pending',
      rejectionReason: json['rejection_reason']?.toString(),
      visibility: json['visibility']?.toString() ?? 'PUBLIC',
      createdAt: json['created_at']?.toString() ?? '',
      media: media,
      creator: json['creator'] is Map<String, dynamic>
          ? json['creator'] as Map<String, dynamic>
          : null,
      reactionSummary: parsedSummary,
      reactionCount:
          (json['reaction_count'] as num?)?.toInt() ??
          parsedSummary.values.fold(0, (sum, n) => sum + n),
      commentCount:
          (json['comment_count'] as num?)?.toInt() ??
          (json['comments'] is List ? (json['comments'] as List).length : 0),
      myReaction: json['my_reaction']?.toString(),
      comments: (json['comments'] as List? ?? const [])
          .map(
            (item) => PublicAlertComment.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
