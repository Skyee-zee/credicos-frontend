import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const CredicosApp());
}

class CredicosApp extends StatelessWidget {
  const CredicosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CrediCos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(elevation: 0, backgroundColor: Colors.indigo, centerTitle: true),
      ),
      home: const SplashScreen(),
    );
  }
}