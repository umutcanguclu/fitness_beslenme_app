import 'package:dio/dio.dart';
import '../models/auth_tokens.dart';
import '../storage/token_storage.dart';

// Android emulator -> host machine maps to 10.0.2.2.
// For physical device or other platforms, this needs to change.
const apiBaseUrl = 'http://10.0.2.2:3000';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  final Dio _refreshDio; // separate Dio without interceptors to avoid recursion
  void Function()? onAuthExpired; // called when refresh fails -> caller should logout

  ApiClient({required this.tokenStorage})
      : dio = Dio(BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
          validateStatus: (s) => s != null && s < 500,
        )),
        _refreshDio = Dio(BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final tokens = await tokenStorage.read();
        if (tokens != null) {
          options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        // Backend returns 401 with validateStatus<500, so it lands here.
        if (response.statusCode == 401 &&
            response.requestOptions.path != '/auth/refresh' &&
            response.requestOptions.path != '/auth/login' &&
            response.requestOptions.path != '/auth/register/coach' &&
            response.requestOptions.path != '/auth/register/player') {
          final retried = await _retryWithFreshToken(response.requestOptions);
          if (retried != null) {
            handler.resolve(retried);
            return;
          }
        }
        handler.next(response);
      },
    ));
  }

  Future<Response?> _retryWithFreshToken(RequestOptions opts) async {
    final tokens = await tokenStorage.read();
    if (tokens == null) return null;
    try {
      final res = await _refreshDio.post('/auth/refresh',
          data: {'refreshToken': tokens.refreshToken});
      if (res.statusCode != 200) return null;
      final newTokens = AuthTokens.fromJson(res.data as Map<String, dynamic>);
      await tokenStorage.write(newTokens);
      // Retry original request with new token.
      opts.headers['Authorization'] = 'Bearer ${newTokens.accessToken}';
      return await dio.fetch(opts);
    } catch (_) {
      // Refresh failed: clear tokens and signal logout.
      await tokenStorage.clear();
      onAuthExpired?.call();
      return null;
    }
  }
}
