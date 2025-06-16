import 'package:anri/pages/login_page.dart';
import 'package:flutter/material.dart';

// SplashScreen: Menampilkan logo sebelum ke halaman login, tanpa animasi putar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// State class TIDAK LAGI memerlukan 'with SingleTickerProviderStateMixin'
class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    // Logika animasi putar sudah dihapus.
    // Kita hanya menyisakan timer untuk pindah ke halaman login.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000),
            pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Widget RotationTransition sudah dihapus dari sini.
              // Kita hanya menyisakan Hero dan Image.
              Hero(
                tag: 'anriLogo',
                child: Image.asset(
                  'assets/images/anri_logo.png',
                  width: 250,
                  height: 250,
                ),
              ),
              const SizedBox(height: 20),
              
              const SizedBox(height: 10),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent, Colors.blueGrey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Helpdesk',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Metode dispose() tidak lagi diperlukan karena tidak ada controller yang harus di-dispose,
  // namun tidak masalah jika tetap ada.
  @override
  void dispose() {
    super.dispose();
  }
}