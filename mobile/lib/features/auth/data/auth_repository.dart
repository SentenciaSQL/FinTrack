import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/core/models/models.dart';
import 'package:fintrack/core/network/dio_provider.dart';
import 'package:fintrack/core/storage/secure_storage.dart';
import 'package:fintrack/core/theme/theme_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref);
});

class AuthRepository {
  AuthRepository(this._ref);

  final Ref _ref;

  Dio get _dio => _ref.read(dioProvider);

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final auth = AuthResponse.fromJson(response.data!);

      await _persist(auth);

      return auth;
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String language,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'preferredLanguage': language,
          'preferredCurrency': _ref.read(currencyProvider),
        },
      );
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<void> resendVerification(String email) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/resend-verification',
        data: {'email': email},
      );
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<UserProfile> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');

      return UserProfile.fromJson(response.data!);
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<UserProfile> updateProfile({
    required String name,
    required String preferredLanguage,
    required String preferredCurrency,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/users/me',
        data: {
          'name': name,
          'preferredLanguage': preferredLanguage,
          'preferredCurrency': preferredCurrency,
        },
      );

      final user = UserProfile.fromJson(response.data!);

      await _ref
          .read(currencyProvider.notifier)
          .setCurrency(user.preferredCurrency);

      return user;
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put(
        '/users/me/password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<void> logout() async {
    await _ref.read(secureStorageProvider).delete(key: StorageKeys.accessToken);
  }

  Future<String?> token() {
    return _ref.read(secureStorageProvider).read(key: StorageKeys.accessToken);
  }

  Future<void> _persist(AuthResponse auth) async {
    await _ref
        .read(secureStorageProvider)
        .write(key: StorageKeys.accessToken, value: auth.accessToken);

    await _ref
        .read(currencyProvider.notifier)
        .setCurrency(auth.user.preferredCurrency);
  }
}

class AuthSession {
  const AuthSession({this.token, this.user});

  final String? token;
  final UserProfile? user;

  bool get isAuthenticated {
    return token != null && token!.isNotEmpty;
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession> {
  @override
  Future<AuthSession> build() async {
    final repository = ref.read(authRepositoryProvider);

    try {
      final token = await repository.token().timeout(
        const Duration(seconds: 2),
      );

      if (token == null || token.isEmpty) {
        return const AuthSession();
      }

      try {
        final user = await repository.me().timeout(const Duration(seconds: 5));

        await ref
            .read(currencyProvider.notifier)
            .setCurrency(user.preferredCurrency);

        return AuthSession(token: token, user: user);
      } catch (_) {
        return AuthSession(token: token);
      }
    } catch (_) {
      return const AuthSession();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final auth = await ref
          .read(authRepositoryProvider)
          .login(email, password);

      return AuthSession(token: auth.accessToken, user: auth.user);
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String language,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(authRepositoryProvider)
          .register(
            name: name,
            email: email,
            password: password,
            language: language,
          );

      return const AuthSession();
    });
  }

  Future<void> refreshProfile() async {
    final currentSession = state.valueOrNull;

    if (currentSession == null || !currentSession.isAuthenticated) {
      return;
    }

    final user = await ref.read(authRepositoryProvider).me();

    state = AsyncData(AuthSession(token: currentSession.token, user: user));
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();

    state = const AsyncData(AuthSession());
  }
}
