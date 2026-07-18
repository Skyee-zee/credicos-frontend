import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import file layar lain agar dikenali
import 'dashboard_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    await Future.delayed(const Duration(seconds: 2)); 
    
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      // Sekarang DashboardScreen sudah dikenali
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } else {
      // Begitu juga dengan LoginScreen
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.real_estate_agent, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text('CrediCos', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Sistem Keputusan Kredit MARCOS', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 40),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}