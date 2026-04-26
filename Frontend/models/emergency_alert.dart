class EmergencyAlert {
  final String id;
  final String studentId;
  final double latitude;
  final double longitude;
  final String status;
  final String? assignedProctor;
  final String? acknowledgedByUserId;
  final String? acknowledgedByName;
  final String? acknowledgedAt;
  final double? distanceInKm;
  final Map<String, dynamic>? responderLocation;
  final String createdAt;
  final Map<String, dynamic>? student;
  final Map<String, dynamic>? acknowledgedBy;

  EmergencyAlert({
    required this.id,
    required this.studentId,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.assignedProctor,
    this.acknowledgedByUserId,
    this.acknowledgedByName,
    this.acknowledgedAt,
    this.distanceInKm,
    this.responderLocation,
    required this.createdAt,
    this.student,
    this.acknowledgedBy,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'],
      studentId: json['student_id'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] ?? 'active',
      assignedProctor: json['assigned_proctor'],
      acknowledgedByUserId: json['acknowledged_by_user_id']?.toString(),
      acknowledgedByName: json['acknowledged_by_name']?.toString(),
      acknowledgedAt: json['acknowledged_at']?.toString(),
      distanceInKm: json['distance_in_km'] == null
          ? null
          : double.tryParse(json['distance_in_km'].toString()),
      responderLocation: json['responder_location'] is Map<String, dynamic>
          ? json['responder_location'] as Map<String, dynamic>
          : null,
      createdAt: json['created_at'] ?? '',
      student: json['student'],
      acknowledgedBy: json['acknowledgedBy'] is Map<String, dynamic>
          ? json['acknowledgedBy'] as Map<String, dynamic>
          : null,
    );
  }
}
