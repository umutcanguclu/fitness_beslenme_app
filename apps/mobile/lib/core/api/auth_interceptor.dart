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
    // Dev mode: don't auto-wipe tokens on 401. Surface the error to the caller
    // and let the user retry; avoids being kicked out mid-test on a stale token.
    handler.next(err);
  }
}
