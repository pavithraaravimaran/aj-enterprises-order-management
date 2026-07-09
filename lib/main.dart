import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // 🔥 Required for Firestore

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AJ Enterprises',

      // 🎨 GLOBAL THEME
      theme: ThemeData(
        primaryColor: const Color(0xFF1565C0),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 2,
        ),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF212121)),
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF1565C0),
          primary: Color(0xFF1565C0),
          secondary: Color(0xFF42A5F5),
        ),

        floatingActionButtonTheme:
        const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1565C0),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}