import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

/// Injects the access token into outgoing requests and clears it on 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.storage,
    this.onUnauthorized,
  });

  final SecureStorage storage;
  final Future<void> Function()? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      final token = await storage.read(SecureStorageKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await storage.delete(SecureStorageKeys.accessToken);
      await storage.delete(SecureStorageKeys.refreshToken);
      if (onUnauthorized != null) {
        await onUnauthorized!();
      }
    }
    handler.next(err);
  }
}
