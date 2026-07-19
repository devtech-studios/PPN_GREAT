import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../storage/token_storage.dart';

/// Auth Service — จัดการ Login/Logout/ตรวจสอบสถานะ Auth
class AuthService {
  final ApiClient _api = ApiClient();

  /// Login — ส่ง email + password ไปที่ Backend → รับ JWT Token กลับมา
  /// Return: Map ข้อมูล user ถ้าสำเร็จ, throw Exception ถ้าผิดพลาด
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _api.post(
        AuthEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final body = response.data;

      if (body['success'] == true) {
        // เก็บ Token
        await TokenStorage.saveToken(body['data']['token']);
        // เก็บข้อมูล User
        await TokenStorage.saveUser(body['data']['user']);
        return body['data']['user'];
      } else {
        throw Exception(body['error']?['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final body = e.response!.data;
        throw Exception(
            body['error']?['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ (${e.response!.statusCode})');
      }
      throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่อ');
    }
  }

  /// Logout — ส่ง request ไป Backend เพื่อ invalidate token → ลบ token ออกจากเครื่อง
  Future<void> logout() async {
    try {
      await _api.post(AuthEndpoints.logout);
    } catch (_) {
      // ถ้า logout ไม่ได้ (เช่น token หมดอายุแล้ว) ก็ไม่เป็นไร ลบ token เลย
    }
    await TokenStorage.removeToken();
  }

  /// Get Current User — ดึงข้อมูล user ที่ login อยู่
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final response = await _api.get(AuthEndpoints.me);
      final body = response.data;
      if (body['success'] == true) {
        return body['data'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// เช็คว่ามี Token อยู่หรือไม่ (เคย login ไว้)
  Future<bool> isLoggedIn() async {
    return await TokenStorage.hasToken();
  }

  /// ดึงข้อมูล User ที่เก็บไว้ใน local storage (ไม่ต้องเรียก API)
  Future<Map<String, dynamic>?> getCachedUser() async {
    return await TokenStorage.getUser();
  }
}
