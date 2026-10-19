import 'dart:convert';

import 'package:dio/dio.dart';

import '../api/errors.dart';
import '../session/session_manager.dart';

class HttpReply {
  const HttpReply(this.body, this.generation);
  final Object? body;
  final int generation;
}

class DioHttp {
  DioHttp({
    required this.baseUrl,
    required this.session,
    required this.locale,
    Duration receiveTimeout = const Duration(seconds: 15),
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl.toString(),
           responseType: ResponseType.plain,
           connectTimeout: const Duration(seconds: 10),
           sendTimeout: const Duration(seconds: 10),
           receiveTimeout: receiveTimeout,
           followRedirects: false,
           validateStatus: (_) => true,
         ),
       );
  final Uri baseUrl;
  final SessionManager session;
  final String Function() locale;
  final Dio _dio;
  void close() => _dio.close(force: true);
  Future<Never> rejectCredentials(int epoch) async {
    if (!await session.invalidate(epoch)) {
      throw const PlatformError(
        PlatformErrorCode.requestCancelled,
        'An earlier session request was rejected.',
      );
    }
    throw const PlatformError(
      PlatformErrorCode.authTokenExpired,
      'Credentials were rejected. Sign in again.',
    );
  }

  Future<HttpReply> request(
    String path, {
    String method = 'GET',
    Object? data,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) async {
    final target = baseUrl.resolve(path);
    if (!path.startsWith('/') ||
        path.startsWith('//') ||
        path.contains('\\') ||
        target.origin != baseUrl.origin ||
        target.userInfo.isNotEmpty ||
        target.hasFragment) {
      throw const PlatformError(
        PlatformErrorCode.unsupported,
        'Requests must stay inside the configured API origin.',
      );
    }
    final epoch = session.generation;
    final token = authenticated ? session.credentials?.accessToken : null;
    try {
      final response = await _dio.request<String>(
        path,
        data: data,
        cancelToken: cancelToken,
        options: Options(
          method: method,
          headers: {
            'Accept': 'application/json',
            'Accept-Language': locale(),
            'x-auth-token': ?token,
          },
        ),
      );
      if (token != null && epoch != session.generation) {
        throw const PlatformError(
          PlatformErrorCode.requestCancelled,
          'Response belongs to an earlier session.',
        );
      }
      final status = response.statusCode;
      if (status == 401) return await rejectCredentials(epoch);
      if (status == 403) {
        throw const PlatformError(
          PlatformErrorCode.permissionDenied,
          'Request was forbidden.',
        );
      }
      if (status == null || status < 200 || status >= 300) {
        throw PlatformError(
          PlatformErrorCode.serverError,
          'HTTP request failed with status $status.',
        );
      }
      try {
        return HttpReply(jsonDecode(response.data ?? ''), epoch);
      } catch (_) {
        throw const PlatformError(
          PlatformErrorCode.responseMalformed,
          'API response is not valid JSON.',
        );
      }
    } on DioException catch (error) {
      throw PlatformError(switch (error.type) {
        DioExceptionType.cancel => PlatformErrorCode.requestCancelled,
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => PlatformErrorCode.requestTimeout,
        DioExceptionType.badCertificate || DioExceptionType.connectionError =>
          PlatformErrorCode.networkUnreachable,
        _ => PlatformErrorCode.unexpected,
      }, 'HTTP transport failed.');
    }
  }
}
