import 'package:dio/dio.dart';
import '../models/auth_tokens.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final User user;
  final AuthTokens tokens;
  const AuthResult({required this.user, required this.tokens});
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  const AuthException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class AuthApi {
  final ApiClient client;
  AuthApi(this.client);

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await client.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      _ensureOk(res);
      return _parseAuthResult(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<AuthResult> registerCoach({
    required String email,
    required String password,
    required String fullName,
    String? clubName,
  }) async {
    try {
      final res = await client.dio.post('/auth/register/coach', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        if (clubName != null && clubName.trim().isNotEmpty)
          'clubName': clubName.trim(),
      });
      _ensureOk(res);
      return _parseAuthResult(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<AuthResult> registerPlayer({
    required String inviteCode,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final res = await client.dio.post('/auth/register/player', data: {
        'inviteCode': inviteCode.trim().toUpperCase(),
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
      });
      _ensureOk(res);
      return _parseAuthResult(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<User> me() async {
    try {
      final res = await client.dio.get('/auth/me');
      _ensureOk(res);
      return User.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await client.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException {
      // Logout best-effort; local tokens are cleared regardless.
    }
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    try {
      final res = await client.dio.post('/auth/refresh',
          data: {'refreshToken': refreshToken});
      _ensureOk(res);
      return AuthTokens.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  // Returns dev token if email exists in dev mode (so UI can auto-fill).
  // In production, response is generic and dev token is null.
  Future<String?> forgotPassword(String email) async {
    try {
      final res = await client.dio.post('/auth/forgot-password',
          data: {'email': email.trim().toLowerCase()});
      _ensureOk(res);
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return data['devToken'] as String?;
      }
      return null;
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    try {
      final res = await client.dio.post('/auth/reset-password',
          data: {'token': token, 'newPassword': newPassword});
      _ensureOk(res);
    } on DioException catch (e) {
      throw _toAuthException(e);
    }
  }

  void _ensureOk(Response res) {
    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final body = res.data;
    final msg = body is Map<String, dynamic>
        ? (body['message'] as String?) ?? (body['error'] as String?) ?? 'İstek başarısız'
        : 'İstek başarısız';
    throw AuthException(msg, statusCode: code);
  }

  AuthException _toAuthException(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return AuthException('Sunucuya bağlanılamadı (10.0.2.2:3000). API çalışıyor mu?');
    }
    final res = e.response;
    if (res != null) {
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'] as String? ?? data['error'] as String?;
        if (msg != null) return AuthException(msg, statusCode: res.statusCode);
      }
    }
    return AuthException('Beklenmeyen hata: ${e.message ?? e.type.name}');
  }

  AuthResult _parseAuthResult(Map<String, dynamic> json) => AuthResult(
        user: User.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      );
}
