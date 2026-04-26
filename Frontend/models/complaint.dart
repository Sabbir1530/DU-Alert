class Complaint {
  final String id;
  final String category;
  final String title;
  final String description;
  final String status;
  final String? judgementDetails;
  final String? summary;
  final String? summarizedAt;
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final List<Map<String, dynamic>> complainants;
  final List<Map<String, dynamic>> accusedPersons;
  final List<Map<String, dynamic>> media;
  final List<Map<String, dynamic>> statusLog;
  final Map<String, dynamic>? creator;

  Complaint({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.status,
    this.judgementDetails,
    this.summary,
    this.summarizedAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.complainants = const [],
    this.accusedPersons = const [],
    this.media = const [],
    this.statusLog = const [],
    this.creator,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Received',
      judgementDetails: json['judgement_details'],
      summary: json['summary'],
      summarizedAt: json['summarized_at'],
      createdBy: json['created_by'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      complainants: List<Map<String, dynamic>>.from(json['complainants'] ?? []),
      accusedPersons: List<Map<String, dynamic>>.from(
        json['accusedPersons'] ?? [],
      ),
      media: List<Map<String, dynamic>>.from(json['media'] ?? []),
      statusLog: List<Map<String, dynamic>>.from(json['statusLog'] ?? []),
      creator: json['creator'],
    );
  }
}
