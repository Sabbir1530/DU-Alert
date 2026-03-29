import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  static Future<String?> getToken() => _storage.read(key: _tokenKey);
  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);
  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── GET ──
  static Future<Map<String, dynamic>> get(
    String path, {
    bool auth = true,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final resp = await http.get(uri, headers: await _headers(auth: auth));
    return _handleResponse(resp);
  }

  // ── POST (JSON) ──
  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final resp = await http.post(
      uri,
      headers: await _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(resp);
  }

  // ── PATCH (JSON) ──
  static Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final resp = await http.patch(
      uri,
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(resp);
  }

  // ── DELETE ──
  static Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final resp = await http.delete(uri, headers: await _headers());
    return _handleResponse(resp);
  }

  // ── Multipart POST (for file uploads) ──
  static Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    List<File>? files,
    String fileFieldName = 'media',
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final request = http.MultipartRequest('POST', uri);

    final token = await getToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields.addAll(fields);

    if (files != null) {
      for (final file in files) {
        final ext = file.path.split('.').last.toLowerCase();
        String type = 'application';
        String subtype = 'octet-stream';
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
          type = 'image';
          subtype = ext == 'jpg' ? 'jpeg' : ext;
        } else if (['mp4', 'mov'].contains(ext)) {
          type = 'video';
          subtype = ext == 'mov' ? 'quicktime' : ext;
        } else if (ext == 'pdf') {
          type = 'application';
          subtype = 'pdf';
        }
        request.files.add(
          await http.MultipartFile.fromPath(
            fileFieldName,
            file.path,
            contentType: MediaType(type, subtype),
          ),
        );
      }
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);
    return _handleResponse(resp);
  }

  static Map<String, dynamic> _handleResponse(http.Response resp) {
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return body;
    }
    throw ApiException(
      resp.statusCode,
      body['error']?.toString() ??
          body['errors']?.toString() ??
          'Unknown error',
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}
