import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://crfpntlltsgidgsezzoq.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNyZnBudGxsdHNnaWRnc2V6em9xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNDczMTksImV4cCI6MjA4NjcyMzMxOX0.snnP3CMmKfaikUKIQWi2m5DGUKhp32S-C4b9Zib4huA';

void main() async {
  print('Testing Supabase connection...');

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
