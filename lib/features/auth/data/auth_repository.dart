import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository(this._dio, this._storage);

  Future<Map<String, dynamic>> resolveDomain(String email) async {
    final response = await _dio.get(
      ApiEndpoints.resolveDomain,
      queryParameters: {'email': email.trim().toLowerCase()},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final userData = response.data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userData);

    final accessToken = response.data['accessToken'] as String?;
    if (accessToken != null) {
      await _storage.saveTokens(accessToken: accessToken);
    }
    await _storage.saveUserMetadata(
      userId: user.id,
      universityId: user.universityId,
    );

    return user;
  }

  Future<UserModel?> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      return UserModel.fromJson(
        response.data['user'] as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } finally {
      await _storage.clearAll();
    }
  }
}

