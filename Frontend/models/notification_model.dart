class AppNotification {
  final String id;
  final String title;
  final String message;
  final String targetRole;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.targetRole,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      targetRole: json['target_role'] ?? 'all',
      createdAt: json['created_at'] ?? '',
    );
  }
}
