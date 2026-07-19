import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../storage/token_storage.dart';
import 'api_endpoints.dart';

/// API Client — Dio HTTP Client พร้อม JWT Interceptor
/// ใช้เป็นตัวกลางในการเรียก API ทั้งหมดของระบบ
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;

  // GlobalKey สำหรับ Navigator เพื่อ redirect ไป Login เมื่อ token หมดอายุ
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // JWT Interceptor — แนบ Token อัตโนมัติ + จัดการ 401
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await TokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        debugPrint('🌐 ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('✅ ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        debugPrint(
            '❌ ${error.response?.statusCode} ${error.requestOptions.uri}');

        // ถ้าได้ 401 Unauthorized → Token หมดอายุ → redirect ไป Login
        if (error.response?.statusCode == 401) {
          await TokenStorage.removeToken();
          // Navigate to login if we have a navigator context
          if (navigatorKey.currentState != null) {
            navigatorKey.currentState!
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        }

        return handler.next(error);
      },
    ));
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
  }) async {
    return _dio.post(path, data: data);
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
  }) async {
    return _dio.put(path, data: data);
  }

  /// PATCH request
  Future<Response> patch(
    String path, {
    dynamic data,
  }) async {
    return _dio.patch(path, data: data);
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
  }) async {
    return _dio.delete(path, data: data);
  }

  /// POST with FormData (สำหรับ upload file)
  Future<Response> upload(
    String path, {
    required FormData formData,
  }) async {
    return _dio.post(
      path,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
      ),
    );
  }
}
