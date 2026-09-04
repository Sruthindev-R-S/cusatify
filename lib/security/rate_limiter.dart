import 'dart:async';

/// Client-Side Security Rate Limiter & Brute-Force Protection
/// Prevents automated attacks and rapid-fire requests on sensitive endpoints
/// such as authentication, registration, attendance submission, and data mutation.
class SecurityRateLimiter {
  static final SecurityRateLimiter _instance = SecurityRateLimiter._internal();
  factory SecurityRateLimiter() => _instance;
  SecurityRateLimiter._internal();

  // Tracks action attempts: key -> list of attempt timestamps
  final Map<String, List<DateTime>> _attempts = {};

  // Tracks active lockout until timestamp: key -> lockout expiry
  final Map<String, DateTime> _lockouts = {};

  /// Checks if an action is permitted under rate limiting rules.
  /// [key] - Unique identifier for the action/user (e.g. "login:user@email.com", "register:ip")
  /// [maxAttempts] - Maximum allowed attempts within [window]
  /// [window] - Time window to measure attempts
  /// [lockoutDuration] - Duration user is locked out if max attempts exceeded
  bool canAttempt(
    String key, {
    int maxAttempts = 5,
    Duration window = const Duration(minutes: 1),
    Duration lockoutDuration = const Duration(seconds: 30),
  }) {
    final now = DateTime.now();

    // Check if currently locked out
    if (_lockouts.containsKey(key)) {
      final lockoutExpiry = _lockouts[key]!;
      if (now.isBefore(lockoutExpiry)) {
        return false;
      } else {
        _lockouts.remove(key);
      }
    }

    // Clean up expired attempts outside window
    final cutoff = now.subtract(window);
    final history = (_attempts[key] ?? []).where((t) => t.isAfter(cutoff)).toList();
    _attempts[key] = history;

    if (history.length >= maxAttempts) {
      // Trigger lockout
      _lockouts[key] = now.add(lockoutDuration);
      return false;
    }

    return true;
  }

  /// Records an attempt for the specified action key.
  void recordAttempt(String key) {
    final now = DateTime.now();
    final history = _attempts.putIfAbsent(key, () => []);
    history.add(now);
  }

  /// Resets attempts for a key upon successful action (e.g., successful login)
  void reset(String key) {
    _attempts.remove(key);
    _lockouts.remove(key);
  }

  /// Gets remaining lockout seconds, or 0 if not locked out
  int getRemainingLockoutSeconds(String key) {
    if (!_lockouts.containsKey(key)) return 0;
    final remaining = _lockouts[key]!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}
