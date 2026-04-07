import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../screens/login_screen.dart';

/// Global API handler to catch UnauthorizedException
Future<T> handleApi<T>(BuildContext context, Future<T> Function() apiCall) async {
  try {
    return await apiCall();
  } on UnauthorizedException {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    // 🔥 FIX: Use addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Session expired. Please login again."),
          backgroundColor: Colors.red,
        ),
      );
    });

    throw UnauthorizedException();
  } catch (e) {
    rethrow;
  }
}