class EmergencyAlert {
  final String id;
  final String studentId;
  final double latitude;
  final double longitude;
  final String status;
  final String? assignedProctor;
  final String createdAt;
  final Map<String, dynamic>? student;

  EmergencyAlert({
    required this.id,
    required this.studentId,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.assignedProctor,
    required this.createdAt,
    this.student,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'],
      studentId: json['student_id'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] ?? 'active',
      assignedProctor: json['assigned_proctor'],
      createdAt: json['created_at'] ?? '',
      student: json['student'],
    );
  }
}
