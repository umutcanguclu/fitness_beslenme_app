import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient(this.dio);

  final Dio dio;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  );

  dio.interceptors.add(AuthInterceptor(storage: storage));

  if (Env.isDevelopment) {
    dio.interceptors.add(LogInterceptor(
      request: false,
      requestHeader: false,
      requestBody: false,
      responseHeader: false,
      responseBody: false,
      error: true,
      logPrint: (obj) => _devLog(obj.toString()),
    ));
  }

  return ApiClient(dio);
});

void _devLog(String message) {
  // ignore: avoid_print
  print('[api] $message');
}
