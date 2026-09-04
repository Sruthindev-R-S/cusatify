import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'security/security_config.dart';
import 'role_selection_page.dart';
import 'student_home_page.dart';
import 'faculty_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env configuration safely (fallback to build flags if missing)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Graceful fallback for environments where .env is provided via compile-time flags
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    headers: SecurityConfig.secureHeaders,
  );

  // Clear image cache to prevent PathNotFoundException with cached images
  imageCache.clear();
  imageCache.clearLiveImages();

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthGate());
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = supabase.auth.currentSession;
        if (session != null) {
          return const RoleRouter();
        }
        return const RoleSelectionPage();
      },
    );
  }
}

// Checks whether the logged-in user is a student or faculty
// and routes them to the appropriate dashboard.
class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  bool loading = true;
  bool isFaculty = false;

  @override
  void initState() {
    super.initState();
    detectRole();
  }

  Future<void> detectRole() async {
    final uid = supabase.auth.currentUser!.id;

    // Check faculty table first
    final facultyData = await supabase
        .from('faculty')
        .select('uid')
        .eq('uid', uid)
        .maybeSingle();

    if (mounted) {
      setState(() {
        isFaculty = facultyData != null;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (isFaculty) {
      return const FacultyHomePage();
    }
    return const StudentHomePage();
  }
}
