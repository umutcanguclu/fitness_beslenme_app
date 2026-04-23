import 'package:dio/dio.dart';

enum ApiErrorCode {
  validationError,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  rateLimited,
  internalError,
  network,
  unknown,
}

class ApiError implements Exception {
  ApiError({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  final ApiErrorCode code;
  final String message;
  final int? statusCode;
  final Object? details;

  factory ApiError.fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return ApiError(
        code: ApiErrorCode.network,
        message: error.message ?? 'Network error',
      );
    }

    final data = response.data;
    if (data is Map && data['error'] is Map) {
      final body = data['error'] as Map;
      return ApiError(
        code: _parseCode(body['code'] as String?),
        message: (body['message'] as String?) ?? response.statusMessage ?? 'Error',
        statusCode: response.statusCode,
        details: body['details'],
      );
    }

    return ApiError(
      code: _codeForStatus(response.statusCode),
      message: response.statusMessage ?? 'Error',
      statusCode: response.statusCode,
    );
  }

  static ApiErrorCode _parseCode(String? raw) {
    switch (raw) {
      case 'VALIDATION_ERROR':
        return ApiErrorCode.validationError;
      case 'UNAUTHORIZED':
        return ApiErrorCode.unauthorized;
      case 'FORBIDDEN':
        return ApiErrorCode.forbidden;
      case 'NOT_FOUND':
        return ApiErrorCode.notFound;
      case 'CONFLICT':
        return ApiErrorCode.conflict;
      case 'RATE_LIMITED':
        return ApiErrorCode.rateLimited;
      case 'INTERNAL_ERROR':
        return ApiErrorCode.internalError;
      default:
        return ApiErrorCode.unknown;
    }
  }

  static ApiErrorCode _codeForStatus(int? status) {
    if (status == null) return ApiErrorCode.unknown;
    if (status == 400) return ApiErrorCode.validationError;
    if (status == 401) return ApiErrorCode.unauthorized;
    if (status == 403) return ApiErrorCode.forbidden;
    if (status == 404) return ApiErrorCode.notFound;
    if (status == 409) return ApiErrorCode.conflict;
    if (status == 429) return ApiErrorCode.rateLimited;
    if (status >= 500) return ApiErrorCode.internalError;
    return ApiErrorCode.unknown;
  }

  @override
  String toString() => 'ApiError($code, $statusCode, $message)';
}
