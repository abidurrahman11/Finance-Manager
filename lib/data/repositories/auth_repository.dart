import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/constants/app_constants.dart';

class AuthRepository {
  final _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

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
      throw ApiException(
        e.response?.data['message'] ?? 'Registration failed',
        statusCode: e.response?.statusCode,
      );
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
          value: response.data['accessToken']);
      await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: response.data['refreshToken']);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Login failed',
        statusCode: e.response?.statusCode,
      );
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
    await _storage.deleteAll();
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Failed to fetch user',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/change-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Failed to change password',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Failed to send reset email',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await _dio.post('/auth/resend-verification', data: {'email': email});
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data['message'] ?? 'Failed to resend verification',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    return token != null;
  }
}
