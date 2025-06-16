import 'package:anri/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late final FocusNode _passwordFocusNode;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  late AnimationController _auroraController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _passwordFocusNode = FocusNode();

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    );
    
    _loadCredentials();
  }

  @override
  void dispose() {
    _auroraController.dispose();
    _fadeAnimationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _loadCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? username = prefs.getString('username');
    final bool rememberMe = prefs.getBool('rememberMe') ?? false;

    if (rememberMe && username != null) {
      setState(() {
        _usernameController.text = username;
        _rememberMe = rememberMe;
      });
    }
  }

  // --- PERUBAHAN UTAMA DI SINI ---
  void _saveOrClearCredentials() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      // Jika "Remember Me" dicentang, simpan username DAN status login
      await prefs.setBool('isLoggedIn', true); // <-- TAMBAHAN
      await prefs.setString('username', _usernameController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      // Jika tidak, hapus semua data sesi
      await prefs.setBool('isLoggedIn', false); // <-- TAMBAHAN
      await prefs.remove('username');
      await prefs.remove('rememberMe');
    }
  }
  // --- AKHIR PERUBAHAN ---

  void _handleLogin() async {
    HapticFeedback.lightImpact();
    
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (_usernameController.text == 'anri' && _passwordController.text == 'anri123') {
        // Panggil fungsi yang sudah dimodifikasi
        _saveOrClearCredentials();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Username or Password incorrect.';
        });
      }
    }
  }

  // ... sisa kode build() tidak berubah ...
  // (Untuk keringkasan, saya tidak menyertakan lagi method build() karena tidak ada perubahan di sana)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(height: 60),
                          Hero(
                            tag: 'anriLogo',
                            child: Image.asset(
                              'assets/images/anri_logo.png',
                              width: 200,
                              height: 200,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedBuilder(
                            animation: _auroraController,
                            builder: (context, child) {
                              final double value = _auroraController.value;
                              final Alignment begin = Alignment(math.sin(value * 2 * math.pi * 1.2), math.cos(value * 2 * math.pi));
                              final Alignment end = Alignment(math.cos(value * 2 * math.pi), math.sin(value * 2 * math.pi * 1.5));
                              return ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [Colors.blue.shade300, Colors.blue.shade700, Colors.lightBlueAccent],
                                  begin: begin, end: end,
                                ).createShader(bounds),
                                child: const Text('Helpdesk',
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: _usernameController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
                            decoration: const InputDecoration(
                              labelText: 'Username / NIP',
                              hintText: 'Enter your Username or NIP',
                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              prefixIcon: Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Username or NIP cannot be empty';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your Password',
                              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onFieldSubmitted: (_) => _handleLogin(),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Password cannot be empty';
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (bool? newValue) => setState(() => _rememberMe = newValue!),
                                    activeColor: Colors.blue.shade700,
                                  ),
                                  const Text('Remember Me', style: TextStyle(color: Colors.blueGrey)),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Forgot Password?', style: TextStyle(color: Colors.blue)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 8,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('LOGIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}