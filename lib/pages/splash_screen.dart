import 'package:anri/home_page.dart';
import 'package:anri/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Panggil fungsi pengecekan login
    _checkLoginStatus();
  }

  // --- FUNGSI BARU UNTUK CEK LOGIN ---
  Future<void> _checkLoginStatus() async {
    // Beri jeda minimal agar splash screen terlihat
    await Future.delayed(const Duration(seconds: 3));

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Cek flag 'isLoggedIn', jika tidak ada, anggap false
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (mounted) {
      if (isLoggedIn) {
        // Jika sudah login, langsung ke HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Jika belum, ke LoginPage
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    }
  }
  // --- AKHIR FUNGSI CEK LOGIN ---

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ... sisa kode build() tidak berubah ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Color(0xFFE0F2F7),
              Color(0xFFBBDEFB),
              Colors.blueAccent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'anriLogo',
                    child: Image.asset(
                      'assets/images/anri_logo.png',
                      width: 250,
                      height: 250,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) {
                      final double value = _controller.value;
                      final Alignment begin = Alignment(math.sin(value * 2 * math.pi * 2.0), math.cos(value * 2 * math.pi * 1.5));
                      final Alignment end = Alignment(math.cos(value * 2 * math.pi * 1.2), math.sin(value * 2 * math.pi * 2.5));
                      return LinearGradient(
                        colors: [Colors.blue.shade300, Colors.blue.shade700, Colors.lightBlueAccent],
                        begin: begin,
                        end: end,
                      ).createShader(bounds);
                    },
                    child: const Text(
                      'Helpdesk',
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}