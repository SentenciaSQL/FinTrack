class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

/// True when [value] is an HTTP client or framework message, not copy for users.
bool isTechnicalErrorText(String value) {
  final text = value.toLowerCase();
  return text.contains('requestoptions') ||
      text.contains('validatestatus') ||
      text.contains('dioexception') ||
      text.contains('status code of') ||
      text.contains('developer.mozilla.org') ||
      text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('handshakeexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection errored') ||
      text.contains('xmlhttprequest') ||
      text.contains('os error');
}
