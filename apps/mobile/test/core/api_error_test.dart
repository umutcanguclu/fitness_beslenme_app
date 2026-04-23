import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/core/api/api_error.dart';

DioException _err({int? status, Object? body}) {
  final requestOptions = RequestOptions(path: '/x');
  return DioException(
    requestOptions: requestOptions,
    response: status == null
        ? null
        : Response(requestOptions: requestOptions, statusCode: status, data: body),
    message: 'boom',
  );
}

void main() {
  test('ApiError.fromDio maps server envelope', () {
    final error = ApiError.fromDio(_err(
      status: 401,
      body: {'error': {'code': 'UNAUTHORIZED', 'message': 'Bad creds'}},
    ));
    expect(error.code, ApiErrorCode.unauthorized);
    expect(error.message, 'Bad creds');
    expect(error.statusCode, 401);
  });

  test('ApiError.fromDio falls back on unknown code', () {
    final error = ApiError.fromDio(_err(
      status: 409,
      body: {'error': {'code': 'WEIRD', 'message': 'nope'}},
    ));
    expect(error.code, ApiErrorCode.unknown);
  });

  test('ApiError.fromDio returns network code when response missing', () {
    final error = ApiError.fromDio(_err());
    expect(error.code, ApiErrorCode.network);
  });

  test('ApiError.fromDio infers code from status when no envelope', () {
    final error = ApiError.fromDio(_err(status: 429, body: null));
    expect(error.code, ApiErrorCode.rateLimited);
  });
}
