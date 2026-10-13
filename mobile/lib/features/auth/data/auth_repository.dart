import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fintrack/core/constants/storage_keys.dart';
import 'package:fintrack/features/auth/data/sso_browser.dart';
import 'package:fintrack/core/localization/locale_provider.dart';
import 'package:fintrack/core/errors/api_exception.dart';
import 'package:fintrack/core/models/models.dart';
import 'package:fintrack/core/network/dio_provider.dart';
import 'package:fintrack/core/storage/secure_storage.dart';
import 'package:fintrack/core/theme/theme_provider.dart';
import 'package:fintrack/features/auth/data/biometric_auth.dart';
import 'package:fintrack/routing/return_path.dart';

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
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String language,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'preferredLanguage': language,
          'preferredCurrency': _ref.read(currencyProvider),
        },
      );
      final auth = AuthResponse.fromJson(response.data!);
      await _persist(auth);
      return auth;
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<UserProfile> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      return UserProfile.fromJson(response.data!);
    } catch (e) {
      throw toApiException(e);
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
    } catch (e) {
      throw toApiException(e);
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
    } catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> logout() async {
    await _ref.read(secureStorageProvider).delete(key: StorageKeys.accessToken);
  }

  Future<List<SsoProvider>> ssoProviders() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/auth/sso/providers',
        options: Options(extra: const {'skipAuth': true}),
      );
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SsoProvider.fromJson)
          .toList();
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<SsoCompletion> signInWithProvider({
    required String provider,
    required String intent,
    required String language,
    required String currency,
    String? returnPath,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/sso/start',
        data: {
          'provider': provider,
          'intent': intent,
          'returnPath': returnPath,
          'preferredLanguage': language,
          'preferredCurrency': currency,
        },
        options: Options(
          extra: {'skipAuth': intent != 'link'},
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      final body = response.data ?? const {};
      final authorizationUrl = body['authorizationUrl'] as String?;
      final state = body['state'] as String?;
      if (authorizationUrl == null ||
          authorizationUrl.isEmpty ||
          state == null ||
          state.isEmpty) {
        throw ApiException(message: '', code: 'SSO_INVALID');
      }
      final callback = await openSsoBrowser(authorizationUrl);
      final parsed = Uri.parse(callback);
      final callbackError = parsed.queryParameters['error'];
      if (callbackError != null && callbackError.isNotEmpty) {
        throw ApiException(message: '', code: callbackError);
      }
      final code = parsed.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw ApiException(message: '', code: 'SSO_INVALID');
      }
      final exchanged = await _dio.post<Map<String, dynamic>>(
        '/auth/sso/exchange',
        data: {'code': code, 'state': state},
        options: Options(
          extra: const {'skipAuth': true},
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      );
      final completion = SsoCompletion.fromJson(exchanged.data ?? const {});
      if (completion is SsoAuthenticated) {
        await _persist(completion.auth);
      }
      return completion;
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      if (code.contains('cancel')) {
        throw ApiException(message: '', code: 'SSO_CANCELLED');
      }
      throw ApiException(message: '', code: 'SSO_PROVIDER_ERROR');
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<SsoAuthenticated> linkWithPassword({
    required String linkToken,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/sso/link',
        data: {'linkToken': linkToken, 'password': password},
        options: Options(
          extra: const {'skipAuth': true},
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      final completion = SsoCompletion.fromJson(response.data ?? const {});
      if (completion is! SsoAuthenticated) {
        throw ApiException(message: '', code: 'SSO_INVALID');
      }
      await _persist(completion.auth);
      return completion;
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<AuthMethods> authMethods() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/me/auth-methods',
      );
      return AuthMethods.fromJson(response.data ?? const {});
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<void> unlinkProvider(String provider) async {
    try {
      await _dio.delete('/users/me/auth-methods/$provider');
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<void> setInitialPassword(String newPassword) async {
    try {
      await _dio.post(
        '/users/me/password',
        data: {'newPassword': newPassword},
      );
    } catch (error) {
      throw toApiException(error);
    }
  }

  Future<String?> ssoLogoutUrl() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/sso/logout');
      final url = response.data?['url'];
      return url is String && url.isNotEmpty ? url : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> token() =>
      _ref.read(secureStorageProvider).read(key: StorageKeys.accessToken);

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
  bool get isAuthenticated => token != null && token!.isNotEmpty;
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession>(AuthController.new);

final sessionNoticeProvider = NotifierProvider<SessionNotice, bool>(
  SessionNotice.new,
);

class SessionNotice extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;

  void dismiss() => state = false;
}

class AuthController extends AsyncNotifier<AuthSession> {
  var _restoring = false;

  @override
  Future<AuthSession> build() async {
    _restoring = true;
    ref.listen<int>(sessionEpochProvider, (previous, next) {
      if (previous == null || next == previous) {
        return;
      }
      Future<void>(() => expireSession());
    });
    final repo = ref.read(authRepositoryProvider);
    // The Android keystore often throws on the first read after the process
    // is recreated. Retry that case, but never overlap a read that timed out:
    // the platform call can still be in flight and a second one can stall.
    try {
      final token = await _readStoredToken(repo);
      if (token == null || token.isEmpty) {
        return const AuthSession();
      }
      try {
        final user = await repo.me().timeout(const Duration(seconds: 5));
        await ref
            .read(currencyProvider.notifier)
            .setCurrency(user.preferredCurrency);
        return AuthSession(token: token, user: user);
      } catch (error) {
        if (_isSessionRejected(error)) {
          await repo.logout();
          Future<void>(() {
            try {
              ref.read(sessionNoticeProvider.notifier).show();
            } catch (_) {
              // The app container can be disposed before this turn runs.
            }
          });
          return const AuthSession();
        }
        return AuthSession(token: token);
      }
    } finally {
      _restoring = false;
    }
  }

  Future<void> expireSession() async {
    if (_restoring) {
      return;
    }
    try {
      if (state.valueOrNull?.isAuthenticated != true) {
        return;
      }
      await ref.read(authRepositoryProvider).logout();
      state = const AsyncData(AuthSession());
      ref.read(biometricLockProvider.notifier).lock();
      ref.read(sessionNoticeProvider.notifier).show();
    } catch (_) {
      // The provider was disposed while the rejected request was finishing.
    }
  }

  bool _isSessionRejected(Object error) {
    if (error is TimeoutException) {
      return false;
    }
    final api = toApiException(error);
    return api.code == 'UNAUTHORIZED' || api.statusCode == 401;
  }

  Future<String?> _readStoredToken(AuthRepository repo) async {
    const timeout = Duration(seconds: 6);
    try {
      return await repo.token().timeout(timeout);
    } on TimeoutException {
      return null;
    } catch (_) {
      try {
        return await repo.token().timeout(timeout);
      } catch (_) {
        return null;
      }
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
    _unlockAfterPassword();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String language,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = await ref
          .read(authRepositoryProvider)
          .register(
            name: name,
            email: email,
            password: password,
            language: language,
          );
      return AuthSession(token: auth.accessToken, user: auth.user);
    });
    _unlockAfterPassword();
  }

  void _unlockAfterPassword() {
    if (state.valueOrNull?.isAuthenticated == true) {
      ref.read(biometricLockProvider.notifier).unlock();
    }
  }

  Future<void> refreshProfile() async {
    final current = state.valueOrNull;
    if (current == null || !current.isAuthenticated) {
      return;
    }
    final user = await ref.read(authRepositoryProvider).me();
    state = AsyncData(AuthSession(token: current.token, user: user));
  }

  Future<void> adopt(AuthResponse auth) async {
    state = AsyncData(AuthSession(token: auth.accessToken, user: auth.user));
    ref.read(biometricLockProvider.notifier).unlock();
  }

  Future<void> logout() async {
    final endSession = await ref.read(authRepositoryProvider).ssoLogoutUrl();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthSession());
    ref.read(biometricLockProvider.notifier).lock();
    if (endSession != null) {
      try {
        await openSsoBrowser(endSession);
      } catch (_) {
        // Local sign-out already succeeded. Closing the provider page is enough.
      }
    }
  }
}

class SsoProvider {
  const SsoProvider({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory SsoProvider.fromJson(Map<String, dynamic> json) => SsoProvider(
    id: json['id'] as String? ?? '',
    displayName: json['displayName'] as String? ?? '',
  );
}

sealed class SsoCompletion {
  const SsoCompletion();

  factory SsoCompletion.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? '';
    final returnPath = json['returnPath'] as String?;
    switch (status) {
      case 'authenticated':
        return SsoAuthenticated(
          auth: AuthResponse.fromJson(json),
          returnPath: returnPath,
        );
      case 'link_required':
        return SsoLinkRequired(
          linkToken: json['linkToken'] as String? ?? '',
          email: json['email'] as String? ?? '',
          provider: json['provider'] as String? ?? '',
          providerDisplayName: json['providerDisplayName'] as String? ?? '',
          canUsePassword: json['canUsePassword'] as bool? ?? false,
          returnPath: returnPath,
        );
      case 'linked':
        return SsoLinked(
          provider: json['provider'] as String? ?? '',
          providerDisplayName: json['providerDisplayName'] as String? ?? '',
          email: json['email'] as String?,
        );
      default:
        throw ApiException(message: '', code: 'SSO_INVALID');
    }
  }
}

class SsoAuthenticated extends SsoCompletion {
  const SsoAuthenticated({required this.auth, this.returnPath});

  final AuthResponse auth;
  final String? returnPath;
}

class SsoLinkRequired extends SsoCompletion {
  const SsoLinkRequired({
    required this.linkToken,
    required this.email,
    required this.provider,
    required this.providerDisplayName,
    required this.canUsePassword,
    this.returnPath,
  });

  final String linkToken;
  final String email;
  final String provider;
  final String providerDisplayName;
  final bool canUsePassword;
  final String? returnPath;
}

class SsoLinked extends SsoCompletion {
  const SsoLinked({
    required this.provider,
    required this.providerDisplayName,
    this.email,
  });

  final String provider;
  final String providerDisplayName;
  final String? email;
}

class AuthMethods {
  const AuthMethods({
    required this.hasPassword,
    required this.methods,
    required this.availableProviders,
  });

  final bool hasPassword;
  final List<LinkedAuthMethod> methods;
  final List<SsoProvider> availableProviders;

  factory AuthMethods.fromJson(Map<String, dynamic> json) => AuthMethods(
    hasPassword: json['hasPassword'] as bool? ?? false,
    methods: (json['methods'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(LinkedAuthMethod.fromJson)
        .toList(),
    availableProviders: (json['availableProviders'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SsoProvider.fromJson)
        .toList(),
  );
}

class LinkedAuthMethod {
  const LinkedAuthMethod({
    required this.provider,
    required this.displayName,
    required this.linkedAt,
    this.email,
  });

  final String provider;
  final String displayName;
  final String? email;
  final DateTime linkedAt;

  factory LinkedAuthMethod.fromJson(Map<String, dynamic> json) =>
      LinkedAuthMethod(
        provider: json['provider'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        email: json['email'] as String?,
        linkedAt: DateTime.tryParse(json['linkedAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}

final ssoProvidersProvider = FutureProvider<List<SsoProvider>>((ref) async {
  return ref.watch(authRepositoryProvider).ssoProviders();
});

final authMethodsProvider = FutureProvider.autoDispose<AuthMethods>((
  ref,
) async {
  final session = ref.watch(authControllerProvider);
  if (session.valueOrNull?.isAuthenticated != true) {
    throw ApiException(message: '', code: 'UNAUTHORIZED');
  }
  return ref.watch(authRepositoryProvider).authMethods();
});

class SsoFlowState {
  const SsoFlowState({this.busyProviderId});

  final String? busyProviderId;
  bool get isBusy => busyProviderId != null;
}

class SsoFlow extends Notifier<SsoFlowState> {
  Future<SsoCompletion>? _inFlight;

  @override
  SsoFlowState build() => const SsoFlowState();

  Future<SsoCompletion?> start({
    required String provider,
    required String intent,
    String? returnPath,
  }) {
    final current = _inFlight;
    if (current != null) {
      return Future.value(null);
    }
    final run = _start(
      provider: provider,
      intent: intent,
      returnPath: returnPath,
    );
    _inFlight = run;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) {
        _inFlight = null;
      }
    });
  }

  Future<SsoCompletion> _start({
    required String provider,
    required String intent,
    String? returnPath,
  }) async {
    state = SsoFlowState(busyProviderId: provider);
    try {
      final completion = await ref
          .read(authRepositoryProvider)
          .signInWithProvider(
            provider: provider,
            intent: intent,
            language: ref.read(localeProvider).languageCode,
            currency: ref.read(currencyProvider),
            returnPath: sanitizeReturnPath(returnPath),
          );
      if (completion is SsoAuthenticated) {
        final back = sanitizeReturnPath(completion.returnPath);
        if (back != null) {
          ref.read(returnPathProvider.notifier).remember(back);
        }
        await ref.read(authControllerProvider.notifier).adopt(completion.auth);
      } else if (completion is SsoLinked) {
        ref.invalidate(authMethodsProvider);
      }
      return completion;
    } finally {
      state = const SsoFlowState();
    }
  }
}

final ssoFlowProvider = NotifierProvider<SsoFlow, SsoFlowState>(SsoFlow.new);
