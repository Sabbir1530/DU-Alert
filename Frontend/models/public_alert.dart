class PublicAlert {
  final String id;
  final String category;
  final String description;
  final String createdBy;
  final bool anonymous;
  final String approvalStatus;
  final String createdAt;
  final List<Map<String, dynamic>> media;
  final Map<String, dynamic>? creator;

  PublicAlert({
    required this.id,
    required this.category,
    required this.description,
    required this.createdBy,
    required this.anonymous,
    required this.approvalStatus,
    required this.createdAt,
    this.media = const [],
    this.creator,
  });

  factory PublicAlert.fromJson(Map<String, dynamic> json) {
    return PublicAlert(
      id: json['id'],
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['created_by'] ?? '',
      anonymous: json['anonymous'] ?? false,
      approvalStatus: json['approval_status'] ?? 'Pending',
      createdAt: json['created_at'] ?? '',
      media: List<Map<String, dynamic>>.from(json['media'] ?? []),
      creator: json['creator'],
    );
  }
}
