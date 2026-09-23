import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/main/presentation/main_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:skindisease/splash_screen.dart';
import 'package:skindisease/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Init Firebase pakai config dari flutterfire configure
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SkindiseaseApp());
}

class SkindiseaseApp extends StatelessWidget {
  const SkindiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F4E20);
    const bgSoftGreen = Color(0xFFF2F7F3);

    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: primaryGreen),
      scaffoldBackgroundColor: bgSoftGreen,
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'DermaCare',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/auth': (_) => const AuthGate(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/main': (_) => const MainScreen(),
      },
    );
  }
}
