import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  // Using 10.0.2.2 for android emulator local access, fallback to localhost
  static const String _defaultBaseUrl = 'http://172.20.10.14:8080/api';

  String get baseUrl => _defaultBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String? token = await user.getIdToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    } else {
      // Offline / Developer bypass fallback token for testing
      headers['Authorization'] = 'Bearer dev-token-pelanggan-dimas';
    }

    return headers;
  }

  Future<http.Response> get(String path) async {
    final String url = '$baseUrl$path';
    final headers = await _getHeaders();
    log('GET Request: $url');
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      log('GET Response Code [${response.statusCode}] for: $url');
      return response;
    } catch (e) {
      log('GET Error for $url: $e');
      rethrow;
    }
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final String url = '$baseUrl$path';
    final headers = await _getHeaders();
    log('POST Request: $url | Body: ${jsonEncode(body)}');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      log('POST Response Code [${response.statusCode}] for: $url');
      return response;
    } catch (e) {
      log('POST Error for $url: $e');
      rethrow;
    }
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final String url = '$baseUrl$path';
    final headers = await _getHeaders();
    log('PUT Request: $url | Body: ${jsonEncode(body)}');
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      log('PUT Response Code [${response.statusCode}] for: $url');
      return response;
    } catch (e) {
      log('PUT Error for $url: $e');
      rethrow;
    }
  }

  Future<http.Response> delete(String path) async {
    final String url = '$baseUrl$path';
    final headers = await _getHeaders();
    log('DELETE Request: $url');
    try {
      final response = await http.delete(Uri.parse(url), headers: headers);
      log('DELETE Response Code [${response.statusCode}] for: $url');
      return response;
    } catch (e) {
      log('DELETE Error for $url: $e');
      rethrow;
    }
  }

  // Upload image to local server
  Future<String?> uploadImage(String filePath) async {
    final String url = '$baseUrl/upload';
    final headers = await _getHeaders();
    log('Upload Request: $url | File: $filePath');
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      headers.forEach((key, value) {
        if (key != 'Content-Type') {
          request.headers[key] = value;
        }
      });
      request.files.add(await http.MultipartFile.fromPath('image', filePath));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      log('Upload Response Code [${response.statusCode}] for: $url');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['url'] as String?;
      }
      return null;
    } catch (e) {
      log('Upload Error for $url: $e');
      return null;
    }
  }
}
