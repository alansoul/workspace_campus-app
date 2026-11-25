import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:campus_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:campus_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:campus_mobile/features/dashboard/presentation/screens/dashboard_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CampusWorkspaceApp()));
}

class CampusWorkspaceApp extends ConsumerWidget {
  const CampusWorkspaceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Northstar Campus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B57D0),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: authState.when(
        data: (user) {
          if (user == null) return const LoginScreen();
          return const DashboardShell();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => const LoginScreen(),
      ),
    );
  }
}