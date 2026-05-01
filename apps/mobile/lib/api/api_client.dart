import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

// Android emulator -> host machine maps to 10.0.2.2.
// For physical device or other platforms, this needs to change.
const apiBaseUrl = 'http://10.0.2.2:3000';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;

  ApiClient({required this.tokenStorage})
      : dio = Dio(BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
          validateStatus: (s) => s != null && s < 500,
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final tokens = await tokenStorage.read();
        if (tokens != null) {
          options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
        }
        handler.next(options);
      },
    ));
  }
}
