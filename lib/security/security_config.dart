/// Security Configuration for API & Network Client
class SecurityConfig {
  /// Standard security headers applied to Supabase client requests
  static const Map<String, String> secureHeaders = {
    'x-client-info': 'cusatify-flutter-secure-client/1.0',
    'x-connection-pool-size': '20',
    'x-request-retry-count': '3',
    'x-max-retries': '3',
  };

  /// Safely sanitizes error messages to avoid leaking sensitive internal details to the UI
  static String getSafeErrorMessage(dynamic error) {
    final errorString = error.toString();
    if (errorString.contains('SocketException') || errorString.contains('HandshakeException')) {
      return 'Network connection error. Please check your internet connection.';
    }
    if (errorString.contains('JWT') || errorString.contains('token')) {
      return 'Authentication session expired. Please sign in again.';
    }
    if (errorString.contains('429')) {
      return 'Too many requests. Please wait a moment before trying again.';
    }
    if (errorString.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
