import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'DU Alert';
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static const List<String> complaintCategories = [
    'Harassment',
    'Theft',
    'Property Loss',
    'Suspicious Activity',
    'Fraud',
    'Cyber Issue',
    'Other',
  ];

  static const List<String> alertCategories = [
    'Safety Warning',
    'Suspicious Person',
    'Infrastructure Hazard',
    'Natural Disaster',
    'Health Alert',
    'Traffic/Transport',
    'Other',
  ];
}
