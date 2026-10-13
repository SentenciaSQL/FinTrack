import 'package:flutter_riverpod/flutter_riverpod.dart';

const returnPathPrefixes = [
  '/home',
  '/transactions',
  '/budgets',
  '/reports',
  '/more',
  '/profile',
  '/settings',
  '/categories',
  '/savings',
  '/recurring',
];

/// Keeps only in-app routes. A value with a scheme or another host is dropped.
String? sanitizeReturnPath(String? value) {
  if (value == null || value.isEmpty || value.length > 200) {
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri == null || uri.hasScheme || uri.hasAuthority) {
    return null;
  }
  final path = uri.path;
  if (!path.startsWith('/') ||
      path.startsWith('//') ||
      path.contains('..') ||
      path.contains('\\')) {
    return null;
  }
  final allowed = returnPathPrefixes.any(
    (prefix) => path == prefix || path.startsWith('$prefix/'),
  );
  if (!allowed) {
    return null;
  }
  if (uri.query.contains('://') ||
      uri.query.contains('//') ||
      uri.query.contains('\\')) {
    return null;
  }
  return uri.hasQuery ? '$path?${uri.query}' : path;
}

class ReturnPath extends Notifier<String?> {
  @override
  String? build() => null;

  void remember(String location) {
    final path = sanitizeReturnPath(location);
    if (path == null || path == state) {
      return;
    }
    state = path;
  }

  void clear() {
    if (state != null) {
      state = null;
    }
  }
}

final returnPathProvider = NotifierProvider<ReturnPath, String?>(
  ReturnPath.new,
);
