import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('Testing Supabase connection...');

  // Read from environment variables
  final supabaseUrl = Platform.environment['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print('Error: SUPABASE_URL and SUPABASE_ANON_KEY environment variables must be set.');
    print('Usage: dart run --define=SUPABASE_URL=... --define=SUPABASE_ANON_KEY=... test_db_connection.dart');
    return;
  }

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    final supabase = Supabase.instance.client;

    // Test basic connection by trying to get the current user (should be null for anon)
    final currentUser = supabase.auth.currentUser;
    print('Current user: $currentUser');

    // Test database connection by trying to select from a table
    final response = await supabase.from('students').select('*', count: CountOption.exact).limit(1);
    print('Database connection successful. Response: $response');

    print('Supabase connection test passed!');
  } catch (e) {
    print('Supabase connection test failed: $e');
  }
}
