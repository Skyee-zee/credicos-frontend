import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>> getApiHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  return {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token', 
  };
}