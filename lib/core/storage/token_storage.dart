import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Token Storage — จัดการ JWT Token และข้อมูล User ใน Web localStorage
class TokenStorage {
  static const String _tokenKey = 'ppn_jwt_token';
  static const String _userKey = 'ppn_user_data';

  /// บันทึก JWT Token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// ดึง JWT Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// ลบ JWT Token (Logout)
  static Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// บันทึกข้อมูล User (id, email, full_name, role)
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// ดึงข้อมูล User
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  /// เช็คว่ามี Token อยู่หรือไม่ (เคย login ไว้)
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
