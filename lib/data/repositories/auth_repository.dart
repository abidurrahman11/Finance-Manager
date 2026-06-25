import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

  static final localUser = UserModel(
    id: 1,
    name: 'Local User',
    email: 'offline@finance.manager',
    isVerified: true,
  );

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Registration failed');
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: response.data['accessToken'],
      );
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: response.data['refreshToken'],
      );
    } on DioException catch (e) {
      throw _apiException(e, 'Login failed');
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken =
          await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {}
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to fetch user');
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (!await isLoggedIn()) return;
    try {
      await _dio.post('/auth/change-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to change password');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to send reset email');
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await _dio.post('/auth/resend-verification', data: {'email': email});
    } on DioException catch (e) {
      throw _apiException(e, 'Failed to resend verification');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }

  ApiException _apiException(DioException e, String fallback) {
    final response = e.response;
    final data = response?.data;
    
    // Check if the server returned a specific error message
    if (data is Map && data['message'] != null) {
      return ApiException(data['message'].toString(), statusCode: response?.statusCode);
    } else if (data is String && data.isNotEmpty) {
      return ApiException(data, statusCode: response?.statusCode);
    }

    // Handle specific status codes
    if (response?.statusCode == 401) {
      return ApiException('Invalid email or password.', statusCode: 401);
    }
    if (response?.statusCode == 403) {
      return ApiException('Account access forbidden.', statusCode: 403);
    }

    // Handle connection issues
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        'Online connection is unavailable. You can keep using local features offline.',
        statusCode: response?.statusCode,
      );
    }

    return ApiException(fallback, statusCode: response?.statusCode);
  }
}
