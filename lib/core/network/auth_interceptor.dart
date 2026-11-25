import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final SecureStorageService _storage;
  final Dio _dio;

  AuthInterceptor(this._storage, this._dio);

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
    final setCookie = response.headers['set-cookie'];
    if (setCookie != null) {
      for (final cookie in setCookie) {
        if (cookie.startsWith('token=')) {
          final token = cookie.split(';').first.split('=').last;
          if (token.isNotEmpty) {
            await _storage.saveTokens(accessToken: token);
          }
        }
      }
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains(ApiEndpoints.login) &&
        !err.requestOptions.path.contains(ApiEndpoints.refresh)) {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshResponse = await _dio.post(
            ApiEndpoints.refresh,
            options: Options(headers: {'x-refresh-token': refreshToken}),
          );

          if (refreshResponse.statusCode == 200) {
            final newAccessToken = refreshResponse.data['accessToken'];
            if (newAccessToken != null) {
              await _storage.saveTokens(accessToken: newAccessToken);
              final retryOptions = err.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final response = await _dio.fetch(retryOptions);
              return handler.resolve(response);
            }
          }
        } catch (_) {
          await _storage.clearAll();
        }
      }
    }
    return handler.next(err);
  }
}