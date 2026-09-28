import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        final mapped = _mapDioError(error);
        final api = mapped.error;
        if (api is ApiException && api.code == 'UNAUTHORIZED') {
          _invalidateRejectedSession(ref, error.requestOptions.headers['Authorization']);
        }
        handler.next(mapped);
      },
    ),
  );

  return dio;
});

/// Bumped when an authenticated request is rejected so the session can be cleared.
final sessionEpochProvider = NotifierProvider<SessionEpoch, int>(SessionEpoch.new);

class SessionEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void markExpired() => state++;
}

DioException _mapDioError(DioException error) {
  final status = error.response?.statusCode;
  final data = error.response?.data;
  String? code;
  String message = '';

  if (data is Map) {
    final rawCode = data['code'];
    if (rawCode is String && rawCode.isNotEmpty) {
      code = rawCode;
    }
    message = _humanMessage(data) ?? '';
  }

  if (_isCredentialRequest(error.requestOptions)) {
    if (status == 401) {
      code ??= 'INVALID_CREDENTIALS';
    }
  } else if (status == 401) {
    code = 'UNAUTHORIZED';
    message = '';
  } else if (status == 403) {
    code ??= 'FORBIDDEN';
  } else if (_isTransportError(error)) {
    code ??= 'NETWORK_ERROR';
    message = '';
  } else if (status != null && status >= 500) {
    code ??= 'SERVER_ERROR';
    message = '';
  }

  if (isTechnicalErrorText(message)) {
    message = '';
  }

  debugPrint(
    'FinTrack API ${error.requestOptions.method} ${error.requestOptions.uri} '
    'failed status=$status type=${error.type} code=$code',
  );

  return DioException(
    requestOptions: error.requestOptions,
    response: error.response,
    type: error.type,
    error: ApiException(
      message: message,
      statusCode: status,
      code: code,
    ),
  );
}

bool _isCredentialRequest(RequestOptions options) {
  final path = options.uri.path;
  return path.endsWith('/auth/login') || path.endsWith('/auth/register');
}

bool _isTransportError(DioException error) {
  return error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError ||
      (error.type == DioExceptionType.unknown && error.response == null);
}

String? _humanMessage(Map data) {
  for (final key in const ['message', 'detail']) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty && !isTechnicalErrorText(value)) {
      return value.trim();
    }
  }
  return null;
}

void _invalidateRejectedSession(Ref ref, Object? authorization) {
  final rejected = authorization is String && authorization.startsWith('Bearer ')
      ? authorization.substring('Bearer '.length)
      : null;
  if (rejected == null || rejected.isEmpty) {
    return;
  }
  Future<void>(() async {
    try {
      final current = await ref.read(secureStorageProvider).read(key: StorageKeys.accessToken);
      if (current != null && current.isNotEmpty && current != rejected) {
        return;
      }
      await ref.read(secureStorageProvider).delete(key: StorageKeys.accessToken);
      ref.read(sessionEpochProvider.notifier).markExpired();
    } catch (failure) {
      debugPrint('FinTrack could not clear an expired session: $failure');
    }
  });
}

ApiException toApiException(Object error) {
  if (error is ApiException) {
    return error;
  }
  if (error is DioException) {
    final wrapped = error.error;
    if (wrapped is ApiException) {
      return wrapped;
    }
    return _mapDioError(error).error! as ApiException;
  }
  debugPrint('FinTrack unexpected error: $error');
  return ApiException(message: '', code: 'SERVER_ERROR');
}
