import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._(this.baseUrl, this.cookie, this.csrfToken);

  final String baseUrl;
  final String cookie;
  final String csrfToken;
  static ApiClient? current;

  static Future<ApiClient> login(String site, String username, String password) async {
    final base = site.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(base);
    if (uri == null || !uri.hasAuthority || !['https', 'http'].contains(uri.scheme)) {
      throw Exception('Enter a valid ERPNext URL.');
    }
    if (uri.scheme != 'https' && uri.host != '10.0.2.2' && uri.host != 'localhost' && uri.host != '127.0.0.1') {
      throw Exception('Use HTTPS outside local development.');
    }
    final response = await http.post(
      Uri.parse('$base/api/method/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'usr': username, 'pwd': password},
    ).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Sign-in failed. Check credentials and URL.');
    }
    final payload = jsonDecode(response.body);
    if (payload['exc'] != null) throw Exception('Sign-in failed. Check credentials and URL.');
    final cookieHeader = response.headers['set-cookie'] ?? '';
    final sid = RegExp(r'sid=([^;,s]+)').firstMatch(cookieHeader)?.group(1);
    if (sid == null || sid == 'Guest') throw Exception('No valid ERPNext session cookie received.');
    var csrf = (payload['csrf_token'] ?? '').toString();
    csrf = csrf.isNotEmpty ? csrf : (RegExp(r'csrf_token=([^;,s]+)').firstMatch(cookieHeader)?.group(1) ?? '');
    if (csrf.isEmpty) {
      try {
        final csrfResponse = await http.get(
          Uri.parse('$base/api/method/frappe.sessions.get_csrf_token'),
          headers: {'Cookie': 'sid=$sid'},
        ).timeout(const Duration(seconds: 10));
        if (csrfResponse.statusCode >= 200 && csrfResponse.statusCode < 300) {
          final csrfPayload = jsonDecode(csrfResponse.body);
          csrf = (csrfPayload['message'] ?? csrfPayload['csrf_token'] ?? '').toString();
        }
      } catch (_) {
        // The first authenticated request will report a useful error if this endpoint is unavailable.
      }
    }
    final client = ApiClient._(base, 'sid=$sid', csrf);
    current = client;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('employee_hub_site', base);
    await prefs.setString('employee_hub_user', username);
    return client;
  }

  Future<void> logout() async {
    final headers = <String, String>{'Cookie': cookie, 'Content-Type': 'application/x-www-form-urlencoded'};
    if (csrfToken.isNotEmpty) headers['X-Frappe-CSRF-Token'] = csrfToken;
    try {
      await http.post(Uri.parse('$baseUrl/api/method/logout'), headers: headers)
          .timeout(const Duration(seconds: 10));
    } finally {
      current = null;
    }
  }

  Future<dynamic> call(String method, [Map<String, String> args = const {}]) async {
    final headers = <String, String>{
      'Cookie': cookie,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    if (csrfToken.isNotEmpty) headers['X-Frappe-CSRF-Token'] = csrfToken;
    final response = await http.post(
      Uri.parse('$baseUrl/api/method/alienhouse_employee_hub.api.$method'),
      headers: headers,
      body: args,
    ).timeout(const Duration(seconds: 20));
    final payload = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300 || payload['exc'] != null) {
      throw Exception('ERPNext request failed. Check CSRF/session, permissions and site configuration.');
    }
    return payload['message'];
  }
}
