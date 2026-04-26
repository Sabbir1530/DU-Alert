class User {
  final String id;
  final String fullName;
  final String? department;
  final String? registrationNumber;
  final String universityEmail;
  final String phone;
  final String username;
  final String role;
  final String createdAt;

  User({
    required this.id,
    required this.fullName,
    this.department,
    this.registrationNumber,
    required this.universityEmail,
    required this.phone,
    required this.username,
    required this.role,
    this.createdAt = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      department: json['department'],
      registrationNumber: json['registration_number'],
      universityEmail: json['university_email'] ?? '',
      phone: json['phone'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'student',
      createdAt: json['created_at'] ?? '',
    );
  }
}
