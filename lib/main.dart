import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'role_selection_page.dart';
import 'student_home_page.dart';
import 'faculty_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthGate());
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
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
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Check faculty collection first
    final facultyDoc = await FirebaseFirestore.instance
        .collection("faculty")
        .doc(uid)
        .get();

    if (mounted) {
      setState(() {
        isFaculty = facultyDoc.exists;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (isFaculty) {
      return const FacultyHomePage();
    }
    return const StudentHomePage();
  }
}
