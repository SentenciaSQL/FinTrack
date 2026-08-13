import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/constants/app_config.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/errors/api_exception.dart';
import 'package:fintrack/core/storage/secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await ref.read(secureStorageProvider).read(key: StorageKeys.accessToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(_mapDioError(error));
      },
    ),
  );

  return dio;
});

DioException _mapDioError(DioException error) {
  final data = error.response?.data;
  String? code;
  String message = error.message ?? 'Request failed';

  if (data is Map<String, dynamic>) {
    code = data['code'] as String?;
    message = (data['message'] as String?) ?? (data['detail'] as String?) ?? message;
  }

  return DioException(
    requestOptions: error.requestOptions,
    response: error.response,
    type: error.type,
    error: ApiException(
      message: message,
      statusCode: error.response?.statusCode,
      code: code,
    ),
  );
}

ApiException toApiException(Object error) {
  if (error is ApiException) {
    return error;
  }
  if (error is DioException && error.error is ApiException) {
    return error.error! as ApiException;
  }
  if (error is DioException) {
    return ApiException(message: error.message ?? 'Request failed', statusCode: error.response?.statusCode);
  }
  return ApiException(message: error.toString());
}
