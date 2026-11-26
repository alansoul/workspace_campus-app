import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'models/auth_models.dart';
import 'models/user_model.dart';
import 'services/auth_api_service.dart';
import 'services/google_oauth_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authApiServiceProvider),
    ref.watch(secureStorageProvider),
    ref.watch(googleOAuthServiceProvider),
  );
});

class AuthRepository {
  final AuthApiService _api;
  final SecureStorageService _storage;
  final GoogleOAuthService _googleOAuth;

  AuthRepository(this._api, this._storage, this._googleOAuth);

  static const Set<String> _blockedPersonalDomains = {
    'yahoo.com',
    'outlook.com',
    'hotmail.com',
    'icloud.com',
    'aol.com',
    'protonmail.com',
    'mailinator.com',
    'tempmail.com',
    'yopmail.com',
  };

  Future<DomainResolution> resolveDomain(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final parts = cleanEmail.split('@');
    if (parts.length != 2 || !parts[1].contains('.')) {
      return const DomainResolution(allowed: false, isRegistered: false);
    }

    final domain = parts[1];
    if (_blockedPersonalDomains.contains(domain)) {
      return DomainResolution(
        allowed: false,
        isRegistered: false,
        isGmail: false,
        isUniversity: false,
        domain: domain,
        errorMessage:
            'Only @gmail.com or admin-registered campus domains are allowed.',
      );
    }

    try {
      final raw = await _api.resolveDomain(cleanEmail);
      final parsed = DomainResolution.fromJson(raw);
      if (!parsed.allowed) {
        return DomainResolution(
          allowed: false,
          isRegistered: false,
          isGmail: false,
          isUniversity: true,
          domain: domain,
          errorMessage:
              'This university domain is not registered by an administrator.',
        );
      }
      return parsed;
    } catch (_) {
      if (domain == 'gmail.com') {
        return const DomainResolution(
          allowed: true,
          isRegistered: true,
          isGmail: true,
          isUniversity: false,
          domain: 'gmail.com',
        );
      }
      rethrow;
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.login(email: email, password: password);
    return _persistSessionFromPayload(data);
  }

  Future<UserModel> loginWithGoogle() async {
    final accessToken = await _googleOAuth.authenticateWithGoogle();
    await _storage.saveTokens(accessToken: accessToken);
    final user = await getProfile();
    if (user == null) {
      await _storage.clearAll();
      throw Exception('Failed to load Google account profile.');
    }
    await _storage.saveUserMetadata(
      userId: user.id,
      universityId: user.universityId,
    );
    return user;
  }

  Future<String?> requestOtp({
    required String email,
    required OtpPurpose purpose,
    String? turnstileToken,
  }) async {
    final data = await _api.requestOtp(
      email: email,
      purpose: purpose,
      turnstileToken: turnstileToken,
    );
    return data['message'] as String?;
  }

  Future<OtpVerificationResult> verifyOtp({
    required String email,
    required String otp,
    String? fullName,
  }) async {
    final data = await _api.verifyOtp(
      email: email,
      otp: otp,
      fullName: fullName,
    );
    final requiresPasswordSetup =
        data['requiresPasswordSetup'] as bool? ?? false;

    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      throw Exception('Authentication response did not include user profile.');
    }

    final user = requiresPasswordSetup
        ? UserModel.fromJson(userJson)
        : await _persistSessionFromPayload(data);

    return OtpVerificationResult(
      user: user,
      requiresPasswordSetup: requiresPasswordSetup,
      message: data['message'] as String?,
    );
  }

  Future<UserModel> setPassword({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final data = await _api.setPassword(
      email: email,
      password: password,
      fullName: fullName,
    );
    return _persistSessionFromPayload(data);
  }

  Future<UserModel> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final data = await _api.resetPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
    return _persistSessionFromPayload(data);
  }

  Future<String?> requestUniversityOtp({
    required String email,
    required String domain,
  }) async {
    final data = await _api.requestUniversityOtp(email: email, domain: domain);
    return data['message'] as String?;
  }

  Future<UserModel> claimUniversity(UniversityClaimRequest request) async {
    final data = await _api.claimUniversity(request);
    return _persistSessionFromPayload(data);
  }

  Future<UserModel?> getProfile() async {
    try {
      final data = await _api.getProfile();
      final userData = data?['user'] as Map<String, dynamic>?;
      if (userData == null) return null;
      return UserModel.fromJson(userData);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await _storage.clearAll();
    }
  }

  Future<UserModel> _persistSessionFromPayload(
    Map<String, dynamic> data,
  ) async {
    final userData = data['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw Exception('Invalid session payload returned by server.');
    }
    final user = UserModel.fromJson(userData);

    final accessToken =
        (data['accessToken'] as String?) ?? (data['token'] as String?);
    if (accessToken != null && accessToken.isNotEmpty) {
      await _storage.saveTokens(accessToken: accessToken);
    }

    await _storage.saveUserMetadata(
      userId: user.id,
      universityId: user.universityId,
    );

    return user;
  }
}
