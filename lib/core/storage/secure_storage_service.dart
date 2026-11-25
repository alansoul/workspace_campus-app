import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  ));
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _universityIdKey = 'university_id';

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async => await _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() async => await _storage.read(key: _refreshTokenKey);

  Future<void> saveUserMetadata({required String userId, String? universityId}) async {
    await _storage.write(key: _userIdKey, value: userId);
    if (universityId != null) {
      await _storage.write(key: _universityIdKey, value: universityId);
    }
  }

  Future<String?> getUserId() async => await _storage.read(key: _userIdKey);
  Future<String?> getUniversityId() async => await _storage.read(key: _universityIdKey);

  Future<void> clearAll() async => await _storage.deleteAll();
}