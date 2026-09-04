import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Secure Supabase Configuration
/// Loads credentials dynamically from environment variables or compile-time flags
/// preventing any hardcoded secrets in the codebase.
class SupabaseConfig {
  static String get supabaseUrl {
    return dotenv.env['SUPABASE_URL'] ??
        const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  }

  static String get supabaseAnonKey {
    return dotenv.env['SUPABASE_ANON_KEY'] ??
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  }

  /// Validates that required credentials are properly loaded
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

// Backward-compatible getters
String get supabaseUrl => SupabaseConfig.supabaseUrl;
String get supabaseAnonKey => SupabaseConfig.supabaseAnonKey;
