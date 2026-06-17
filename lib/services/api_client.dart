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
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                // Disabled encryptedSharedPreferences for wider compatibility with
                // budget phones like Infinix Smart series which often have
                // broken hardware-backed security implementations.
                encryptedSharedPreferences: false,
              ),
            ),
        dio = dio ?? Dio() {
    this.dio.options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'SmartQueueMobile/1.0',
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
              try {
                final token = tokenReader != null
                    ? await tokenReader()
                    : await _storage.read(key: AppConstants.tokenKey);
                if (token != null && token.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
              } catch (e) {
                await _storage.deleteAll();
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
  }) async {
    final response = await dio.get(path, queryParameters: queryParameters);
    _fixImageUrls(response.data);
    return response;
  }

  /// Recursively find any string containing "localhost", "127.0.0.1" or starting with "/"
  /// and replace it with the real live backend URL to ensure images always show.
  void _fixImageUrls(dynamic data) {
    if (data is List) {
      for (var item in data) {
        _fixImageUrls(item);
      }
    } else if (data is Map) {
      for (var key in data.keys) {
        final val = data[key];
        if (val is String && (val.contains('http://127.0.0.1') || val.contains('http://localhost'))) {
          // Replace local URLs with the real deployed Render URL
          data[key] = val.replaceFirst(RegExp(r'http://(127\.0\.0\.1|localhost):8000'), AppConstants.baseUrl.replaceFirst('/api', ''));
        } else if (val is Map || val is List) {
          _fixImageUrls(val);
        }
      }
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    final response = await dio.post(path, data: data, options: options);
    _fixImageUrls(response.data);
    return response;
  }

  Future<Response<dynamic>> put(String path, {dynamic data}) =>
      dio.put(path, data: data);

  Future<Response<dynamic>> delete(String path) => dio.delete(path);
}
