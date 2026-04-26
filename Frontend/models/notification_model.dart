class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? referenceType;
  final String? referenceId;
  final String? referenceSubId;
  final bool isRead;
  final String createdAt;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.referenceType,
    required this.referenceId,
    required this.referenceSubId,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      referenceType: json['reference_type']?.toString(),
      referenceId: json['reference_id']?.toString(),
      referenceSubId: json['reference_sub_id']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : <String, dynamic>{},
    );
  }
}
