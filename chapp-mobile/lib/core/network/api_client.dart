import 'package:dio/dio.dart';

import '../error/exception.dart';
import '../session/session_manager.dart';
import 'api_constants.dart';

/// Configured Dio client for the backend REST API.
///
/// Attaches the bearer token on every request and exposes [dio] for the data
/// sources. Use [mapDioError] in catch blocks to convert transport/HTTP errors
/// into the app's exception types (which repositories map to [Failure]s).
class ApiClient {
  ApiClient({required SessionManager session, String? baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? ApiConstants.baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 60),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = session.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
}

/// Translate a [DioException] into one of the app's [Exception] types.
Exception mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return TimeoutException();
    case DioExceptionType.connectionError:
      return NetworkException();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode ?? 0;
      final message = _detail(e.response?.data) ?? 'Request failed ($status)';
      if (status == 401) return UnauthorizedException(message);
      if (status == 403) return ForbiddenException(message);
      if (status == 404) return NotFoundException(message);
      if (status == 409 || status == 422 || status == 400) {
        return ServerException(message);
      }
      return ServerException(message);
    default:
      return UnknownException(e.message ?? 'Something went wrong');
  }
}

/// FastAPI returns errors as `{"detail": "..."}` (or a validation list).
String? _detail(dynamic data) {
  if (data is Map && data['detail'] != null) {
    final detail = data['detail'];
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] != null) return first['msg'].toString();
    }
    return detail.toString();
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}
