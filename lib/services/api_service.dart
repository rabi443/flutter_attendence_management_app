import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = "Token expired or unauthorized"]);

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl =
      "https://enthusiastic-maroon-hamster.103-233-58-171.cpanel.site/api";

  // 🔑 Get stored token
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 🔥 Common header builder
  static Future<Map<String, String>> getHeaders(
      {bool isJson = false}) async {
    String? token = await getToken();

    return {
      'Accept': 'application/json',
      if (isJson) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 🔐 LOGIN
  static Future<Map<String, dynamic>?> login(
      String email, String password, bool remember) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: await getHeaders(isJson: true),
      body: jsonEncode({
        'email': email,
        'password': password,
        'remember': remember ? 'true' : 'false',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // 🚪 LOGOUT
  static Future<bool> logout() async {
    final response = await http.post(
      Uri.parse("$baseUrl/logout"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    return response.statusCode == 200;
  }

  // 🔁 FORGOT PASSWORD
  static Future forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      body: {'email': email},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // 📥 GET DATA
  static Future<List<dynamic>> getData(String endpoint) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] ?? [];
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    throw Exception("Failed to load data");
  }

  // 📊 DASHBOARD
  static Future<Map<String, dynamic>> getDashboardData() async {
    final response = await http.get(
      Uri.parse("$baseUrl/dashboard"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] ?? {};
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    throw Exception("Failed to load dashboard");
  }

  // ❌ DELETE
  static Future<bool> deleteData(String endpoint, int id) async {
    final response = await http.delete(
      Uri.parse("$baseUrl/$endpoint/$id"),
      headers: await getHeaders(),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    return response.statusCode == 200;
  }

  // ➕ CREATE
  static Future<bool> createData(
      String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: await getHeaders(isJson: true),
      body: jsonEncode(data),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    return response.statusCode == 201;
  }

  // ✏️ UPDATE
  static Future<bool> updateData(
      String endpoint, int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$endpoint/$id"),
      headers: await getHeaders(isJson: true),
      body: jsonEncode(data),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    return response.statusCode == 200;
  }
}