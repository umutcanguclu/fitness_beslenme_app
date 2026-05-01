import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

ApiException toApiException(Object e) {
  if (e is DioException) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiException('Sunucuya bağlanılamadı (10.0.2.2:3000). API çalışıyor mu?');
    }
    final res = e.response;
    if (res != null) {
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'] as String? ?? data['error'] as String?;
        if (msg != null) return ApiException(msg, statusCode: res.statusCode);
      }
      return ApiException('HTTP ${res.statusCode ?? '?'}: istek başarısız', statusCode: res.statusCode);
    }
    return ApiException('Beklenmeyen ağ hatası: ${e.message ?? e.type.name}');
  }
  return ApiException('Beklenmeyen hata: $e');
}

void ensureOk(Response res) {
  final code = res.statusCode ?? 0;
  if (code >= 200 && code < 300) return;
  final body = res.data;
  final msg = body is Map<String, dynamic>
      ? (body['message'] as String?) ?? (body['error'] as String?) ?? 'İstek başarısız'
      : 'İstek başarısız';
  throw ApiException(msg, statusCode: code);
}
