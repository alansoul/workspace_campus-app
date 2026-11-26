import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(ref.watch(apiClientProvider));
});

/// Pure HTTP client wrapper for IAM authentication and university onboarding.
class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  Future<Map<String, dynamic>> resolveDomain(String emailOrDomain) async {
    final normalized = emailOrDomain.trim().toLowerCase();
    final domain =
        normalized.contains('@') ? normalized.split('@').last : normalized;
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.resolveDomain,
      queryParameters: {'email': normalized, 'domain': domain},
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> requestOtp({
    required String email,
    required OtpPurpose purpose,
    String? turnstileToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.requestOtp,
      data: {
        'email': email.trim().toLowerCase(),
        'purpose': purpose.apiValue,
        if (turnstileToken != null && turnstileToken.isNotEmpty)
          'turnstileToken': turnstileToken,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    String? fullName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.verifyOtp,
      data: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
        if (fullName != null && fullName.trim().isNotEmpty)
          'fullName': fullName.trim(),
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> setPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.setPassword,
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
        if (fullName != null && fullName.trim().isNotEmpty)
          'fullName': fullName.trim(),
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.resetPassword,
      data: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> requestUniversityOtp({
    required String email,
    required String domain,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.requestUniversityOtp,
      data: {
        'email': email.trim().toLowerCase(),
        'domains': [UniversityClaimRequest.cleanDomain(domain)],
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> claimUniversity(
    UniversityClaimRequest request,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.claimUniversity,
      data: request.toJson(),
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
    return response.data;
  }

  Future<void> logout() async {
    await _dio.post<void>(ApiEndpoints.logout);
  }

  /// Extracts readable error text from NestJS JSON responses or Dio failures.
  static String extractErrorMessage(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is List && message.isNotEmpty) {
          return message.map((item) => item.toString()).join('\n');
        }
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Server is waking up or timed out. Please try again.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Unable to reach server. Check your internet connection.';
      }
    }
    final text = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    return text.trim().isEmpty ? fallback : text;
  }
}
