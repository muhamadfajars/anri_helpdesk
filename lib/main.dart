import 'package:anri/home_page.dart';
import 'package:flutter/material.dart';

// Fungsi utama yang menjalankan aplikasi Flutter
void main() {
  runApp(const MyApp());
}

// Widget utama aplikasi
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ANRI Helpdesk App', // Application title
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, primary: Colors.blue.shade700),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(), // Set the initial page to SplashScreen
    );
  }
}

// SplashScreen: Displays a loading animation before navigating to the login page.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationAnimationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _rotationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Duration for one full rotation
    );
    _rotationAnimation = CurvedAnimation(
      parent: _rotationAnimationController,
      curve: Curves.linear, // Constant rotation speed
    );

    // Start rotation animation immediately
    _rotationAnimationController.repeat();

    // Simulate initial loading time, then navigate to LoginPage
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) { // Check if the widget is still mounted before navigating
        // Navigate using PageRouteBuilder for custom transition duration and effect
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 1000), // Duration of the page transition
            pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // Add a fade transition for the new page
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
              // --- ANRI Logo with Rotation Animation (for Hero transition) ---
              Hero( // Add Hero widget for smooth transition
                tag: 'anriLogo', // Unique tag for the Hero animation
                child: RotationTransition(
                  turns: _rotationAnimation,
                  child: Image.asset(
                    'assets/images/anri_logo.png', // Path to your logo
                    width: 250, // Adjusted size for splash screen
                    height: 250,
                  ),
                ),
              ),
              const SizedBox(height: 20),
             
              const SizedBox(height: 10),
              // --- Gradasi Warna pada Teks "Helpdesk" ---
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.blue, Colors.blueAccent, Colors.blueGrey], // Gradasi warna biru
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Helpdesk', // Teks diubah menjadi "Helpdesk"
                  style: TextStyle(
                    fontSize: 30, // Ukuran font disesuaikan
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Warna teks harus putih agar shader mask terlihat
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rotationAnimationController.dispose();
    super.dispose();
  }
}

// LoginPage: Displays the login form.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Manages loading state only for login attempt
  String? _errorMessage;
  bool _rememberMe = false;

  // --- Variables for Logo Rotation (during login attempt and initial load) ---
  late AnimationController _loginRotationAnimationController;
  late Animation<double> _loginRotationAnimation;

  // --- Variables for Page Fade-in (when navigating from splash) ---
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Inisialisasi AnimationController untuk Rotasi Logo (saat login DAN animasi awal di LoginPage)
    _loginRotationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Durasi satu putaran
    );
    _loginRotationAnimation = CurvedAnimation(
      parent: _loginRotationAnimationController,
      curve: Curves.linear, // Constant rotation speed
    );

    // Inisialisasi AnimationController untuk Fade-in Halaman Login itu sendiri
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Extended fade-in duration
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn, // Fade-in curve
    );

    // Start fade-in animation for LoginPage when it's built
    _fadeAnimationController.forward();

    // === Logo rotation continuity from SplashScreen to LoginPage for 1.5 seconds ===
    _loginRotationAnimationController.repeat(); // Start repeating immediately
    Future.delayed(const Duration(milliseconds: 1500), () { // Stop after 1.5 seconds
      if (mounted) { // Check if the widget is still mounted
        _loginRotationAnimationController.animateTo(
          1.0,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 700),
        ).then((_) {
          if (mounted && _isLoading == false) { // Only reset if not currently in a login loading state
            _loginRotationAnimationController.reset();
            _loginRotationAnimationController.stop(); // Ensure it stops after reset
          }
        });
      }
    });
  }

  // Function called when the login button is pressed
  void _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Activate loading
        _errorMessage = null; // Clear previous error messages
      });

      // Start logo rotation animation if it's not already animating
      // (This prevents restarting if the initial 1.5s rotation is still active)
      if (!_loginRotationAnimationController.isAnimating) {
        _loginRotationAnimationController.repeat();
      }

      // === Simulate API Call ===
      await Future.delayed(const Duration(seconds: 3)); // Simulated API loading time

      // Smoothly stop the logo rotation animation after simulation completes
      _loginRotationAnimationController.animateTo(1.0, curve: Curves.easeOutCubic, duration: const Duration(milliseconds: 700))
        .then((_) {
          if (mounted) { // Check if the widget is still mounted
            _loginRotationAnimationController.reset(); // Reset controller after animation completes
            setState(() {
              _isLoading = false; // Deactivate loading
            });
          }
        });
      
      // Dummy authentication logic:
      if (_usernameController.text == 'anri' && _passwordController.text == 'anri123') {
        print('Login Successful!');
        // TODO: Navigate to the next page (e.g., HomePage)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Username or Password incorrect.';
        });
        print('Login Failed: Username or Password incorrect.');
      }
    } else {
      setState(() {
        _errorMessage = 'Please fill in all fields.';
      });
      print('Validation failed: Username or Password empty.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
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
          child: FadeTransition( // Fade-in animation for the entire content
            opacity: _fadeAnimation,
            child: LayoutBuilder( // Using LayoutBuilder to get the parent's constraints
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  // Constrain the height of SingleChildScrollView to ensure it fills the viewport
                  // This allows the background gradient to extend all the way down
                  // and also handles scrolling when content overflows
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight, // Ensure content minimum height is parent's max height
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start, // Align content to start (top)
                        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally for logo/text
                        children: <Widget>[
                          const SizedBox(height: 60), // Add top spacing for the header area

                          // --- ANRI Logo (Hero transition and rotation during login attempt) and ANRI Text ---
                          Column(
                            children: [
                              Hero( // Add Hero widget with the same tag
                                tag: 'anriLogo',
                                child: RotationTransition(
                                  turns: _loginRotationAnimation, // Using login-specific rotation animation
                                  child: Image.asset(
                                    'assets/images/anri_logo.png', // Logo path
                                    width: 200, // Adjusted size for login page
                                    height: 200, // Adjusted size for login page
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5), // Space between logo and ANRI text (reduced)
                             
                            ],
                          ),
                          const SizedBox(height: 16), // Vertical space
                          // --- Gradasi Warna pada Teks "Helpdesk" ---
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.blue, Colors.blueAccent, Colors.blueGrey], // Gradasi warna biru
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              'Helpdesk', // Teks diubah menjadi "Helpdesk"
                              style: TextStyle(
                                fontSize: 28, // Ukuran font disesuaikan
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Warna teks harus putih agar shader mask terlihat
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // --- Username/NIP Input ---
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username / NIP',
                              hintText: 'Enter your Username or NIP',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.person),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Username or NIP cannot be empty';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // --- Password Input ---
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Enter your Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password cannot be empty';
                              }
                              return null;
                              },
                            ),
                          const SizedBox(height: 15),

                          // --- "Remember Me" Checkbox ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: _rememberMe,
                                    onChanged: (bool? newValue) {
                                      setState(() {
                                        _rememberMe = newValue!;
                                      });
                                    },
                                    activeColor: Colors.blue.shade700,
                                  ),
                                  const Text(
                                    'Remember Me',
                                    style: TextStyle(color: Colors.blueGrey),
                                  ),
                                ],
                              ),
                              // --- Forgot Password ---
                              TextButton(
                                onPressed: () {
                                  print('Forgot Password button pressed');
                                  // TODO: Navigate to reset password page
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // --- Error Message (if any) ---
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // --- Login Button ---
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'LOGIN',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
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

  @override
  void dispose() {
    _loginRotationAnimationController.dispose();
    _fadeAnimationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// TODO: Create HomePage in a separate file (e.g., lib/home_page.dart)
// class HomePage extends StatelessWidget {
//   const HomePage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Application Home')),
//       body: const Center(
//         child: Text('Welcome to ANRI Helpdesk App!'),
//       ),
//     );
//   }
// }

