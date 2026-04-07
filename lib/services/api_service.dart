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
  static const String baseUrl = "https://enthusiastic-maroon-hamster.103-233-58-171.cpanel.site/api";

  // Get stored token
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // LOGIN
  static Future<Map<String, dynamic>?> login(
      String email, String password, bool remember) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
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


  //Logout
  static Future<bool> logout() async {
    String? token = await getToken();

    if (token == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/logout"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 200 means success
    return response.statusCode == 200;
  }

  //FORGOT PASSWORD
  static Future forgotPassword(String email) async {
    var response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      body: {
        'email': email,
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  // GET DATA
  static Future<List<dynamic>> getData(String endpoint) async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] ?? [];
    }

    if (response.statusCode == 401) {
      throw Exception("unauthorized");
    }

    throw Exception("Failed to load data");
  }

  // Dashboard data
  static Future<Map<String, dynamic>> getDashboardData() async {
    String? token = await getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/dashboard"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] ?? {}; // now we return full arrays
    }

    if (response.statusCode == 401) {
      throw Exception("unauthorized");
    }

    throw Exception("Failed to load dashboard");
  }

  // DELETE
  static Future<bool> deleteData(String endpoint, int id) async {
    String? token = await getToken();

    final response = await http.delete(
      Uri.parse("$baseUrl/$endpoint/$id"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  // CREATE
  static Future<bool> createData(
      String endpoint, Map<String, dynamic> data) async {
    String? token = await getToken();

    final response = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 201;
  }

  // UPDATE
  static Future<bool> updateData(
      String endpoint, int id, Map<String, dynamic> data) async {
    String? token = await getToken();

    final response = await http.put(
      Uri.parse("$baseUrl/$endpoint/$id"),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    return response.statusCode == 200;
  }
}