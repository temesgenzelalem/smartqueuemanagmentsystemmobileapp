import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';

typedef TokenReader = Future<String?> Function();

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage _storage;

  ApiClient({
    Dio? dio,
    FlutterSecureStorage? storage,
    TokenReader? tokenReader,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        dio = dio ?? Dio() {
    this.dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (kDebugMode) {
      this.dio.interceptors.add(
            LogInterceptor(
              requestBody: true,
              responseBody: true,
            ),
          );
    }

    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = tokenReader != null
                  ? await tokenReader()
                  : await _storage.read(key: AppConstants.tokenKey);
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              return handler.next(options);
            },
            onError: (error, handler) {
              if (error.response?.statusCode == AppConstants.unauthorized401) {
                // Session expired — UI layers handle logout via auth notifier.
              }
              return handler.next(error);
            },
          ),
        );
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      dio.get(path, queryParameters: queryParameters);

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      dio.post(path, data: data, options: options);

  Future<Response<dynamic>> put(String path, {dynamic data}) =>
      dio.put(path, data: data);

  Future<Response<dynamic>> delete(String path) => dio.delete(path);
}
