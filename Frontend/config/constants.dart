import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'DU Alert';

  static const String _baseUrlFromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_baseUrlFromEnv.isNotEmpty) return _baseUrlFromEnv;

    // Web app runs in the same machine in local dev, so use localhost by default.
    if (kIsWeb) return 'http://localhost:3000';

    // Android emulator fallback for local backend.
    return 'http://10.0.2.2:3000';
  }

  static String get serverOrigin {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return baseUrl;
    }
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
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
