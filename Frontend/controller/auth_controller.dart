import '../models/user.dart';

class AuthController {
  // Mock database with multiple login credentials for different roles
  final Map<String, dynamic> _mockDb = {
    'loginCredentials': [
      {
        'id': '1',
        'email': 's@du.ac.bd',
        'password': 'sabbir123',
        'role': 'Student',
        'name': 'Sabbir Ahmed',
      },
      {
        'id': '2',
        'email': 'arif@du.ac.bd',
        'password': 'arif123',
        'role': 'Proctor',
        'name': 'Arif',
      },
      {
        'id': '3',
        'email': 'admin@du.ac.bd',
        'password': 'admin123',
        'role': 'Proctorial Body',
        'name': 'Dr. Muhammad Khan',
      },
      {
        'id': '4',
        'email': 'superadmin@du.ac.bd',
        'password': 'superadmin123',
        'role': 'Admin',
        'name': 'System Administrator',
      },
    ],
    'currentUser': {
      'id': '1',
      'name': 'Sabbir Ahmed',
      'email': 's@du.ac.bd',
      'phone': '01522112908',
      'role': 'Student',
      'department': 'Software Engineering',
      'session': '2023-2024',
      'hall': 'Shahidullah Hall',
      'regNumber': '1530',
    },
    'otp': {
      'email': 's@du.ac.bd',
      'otp': '123456',
    },
  };

  // Login with credentials from mock database
  Future<Map<String, dynamic>> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final credentials = _mockDb['loginCredentials'] as List<dynamic>;
    
    for (var cred in credentials) {
      if (cred['email'] == email && cred['password'] == password) {
        return {
          'success': true,
          'role': cred['role'],
          'name': cred['name'],
          'email': cred['email'],
        };
      }
    }
    
    return {'success': false, 'message': 'Invalid email or password'};
  }

  // Get current user data from mock database
  Future<User> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final userData = _mockDb['currentUser'] as Map<String, dynamic>;
    return User(
      name: userData['name'] as String,
      email: userData['email'] as String,
      regNumber: userData['regNumber'] as String,
      phone: userData['phone'] as String?,
    );
  }

  // Get all available credentials (for testing purposes)
  Future<List<Map<String, dynamic>>> getAllCredentials() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<Map<String, dynamic>>.from(
      _mockDb['loginCredentials'] as List<dynamic>,
    );
  }

  // Mock registration — returns created User on success.
  Future<User> register(User user, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return user;
  }

  // Mock send OTP / verification
  Future<bool> sendOtp(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // Mock verify OTP - uses mock database OTP
  Future<bool> verifyOtp(String email, String otp) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final mockOtp = _mockDb['otp'] as Map<String, dynamic>;
    return email == mockOtp['email'] && otp == mockOtp['otp'];
  }
}
