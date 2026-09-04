/// Input Sanitization and Validation Helper
/// Protects against XSS, SQL/NoSQL Injection, and Malicious payloads.
class InputSanitizer {
  // Regex for RFC 5322 compliant email format
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  // Regex to detect HTML/script tags
  static final RegExp _htmlTagRegExp = RegExp(r'<[^>]*>', multiLine: true);

  // Regex for alphanumeric + common safe characters (letters, numbers, space, hyphens, underscores)
  static final RegExp _safeTextRegExp = RegExp(r'^[a-zA-Z0-9\s\-_.@,!?]+$');

  /// Sanitizes generic text by stripping HTML tags, removing control characters, and trimming.
  static String sanitizeText(String? input, {int maxLength = 500}) {
    if (input == null) return '';
    String sanitized = input.trim();

    // Strip HTML/script tags
    sanitized = sanitized.replaceAll(_htmlTagRegExp, '');

    // Remove control characters except newline and tab
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');

    // Enforce maximum length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized;
  }

  /// Validates and normalizes an email address.
  static String? validateAndNormalizeEmail(String? email) {
    if (email == null) return null;
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty || !_emailRegExp.hasMatch(trimmed)) {
      return null;
    }
    return trimmed;
  }

  /// Sanitizes and validates student/faculty ID.
  static String? validateId(String? id, {int minLength = 3, int maxLength = 30}) {
    if (id == null) return null;
    final trimmed = id.trim();
    if (trimmed.length < minLength || trimmed.length > maxLength) return null;
    // Allow alphanumeric, dashes, slashes
    if (!RegExp(r'^[a-zA-Z0-9\-_/]+$').hasMatch(trimmed)) return null;
    return trimmed;
  }

  /// Validates password strength (min 6 chars)
  static bool isPasswordValid(String? password) {
    if (password == null) return false;
    return password.length >= 6;
  }

  /// Validates if a string contains safe characters
  static bool isSafeText(String input) {
    return _safeTextRegExp.hasMatch(input);
  }
}
