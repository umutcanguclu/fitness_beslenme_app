import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_error.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/auth_state.dart';

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}

class AuthResponse {
  const AuthResponse({required this.user, required this.tokens});

  final AuthUser user;
  final AuthTokens tokens;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      );
}

class AuthRepository {
  AuthRepository({required ApiClient apiClient, required SecureStorage storage})
      : _dio = apiClient.dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorage _storage;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    String? locale,
  }) {
    return _post(
      '/auth/register',
      {
        'email': email,
        'password': password,
        'name': name,
        'locale': ?locale,
      },
    );
  }

  Future<AuthResponse> login({required String email, required String password}) {
    return _post('/auth/login', {'email': email, 'password': password});
  }

  Future<AuthUser> fetchMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      return AuthUser.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDio(error);
    }
  }

  Future<void> logout() async {
    final refresh = await _storage.read(SecureStorageKeys.refreshToken);
    if (refresh?.isNotEmpty ?? false) {
      try {
        await _dio.post<void>(
          '/auth/logout',
          data: {'refreshToken': refresh},
          options: Options(extra: {'skipAuth': true}),
        );
      } on DioException {
        // Logout is best-effort; we always wipe local tokens.
      }
    }
    await _storage.clear();
  }

  Future<void> persistTokens(AuthTokens tokens) async {
    await _storage.write(SecureStorageKeys.accessToken, tokens.accessToken);
    await _storage.write(SecureStorageKeys.refreshToken, tokens.refreshToken);
  }

  Future<AuthResponse> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(extra: {'skipAuth': true}),
      );
      return AuthResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiError.fromDio(error);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    storage: ref.watch(secureStorageProvider),
  );
});
