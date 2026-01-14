import 'package:flutter/material.dart';
import 'package:projects/app/navigation.dart';
import 'package:projects/services/auth_service.dart'; // Import your AuthService

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Build your repertoire!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _errorMessage = null;
                  });
                  final email = _emailController.text;
                  final password = _passwordController.text;
                  final userCredential = await _authService.signInWithEmailAndPassword(email, password);
                  if (userCredential != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const NavigationBarScreen()),
                    );
                  } else {
                    setState(() {
                      _errorMessage = 'Login failed. Please check your credentials.';
                    });
                  }
                },
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () async {
                  setState(() {
                    _errorMessage = null;
                  });
                  final email = _emailController.text;
                  final password = _passwordController.text;
                  final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
                  if (userCredential != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const NavigationBarScreen()),
                    );
                  } else {
                    setState(() {
                      _errorMessage = 'Registration failed. Please try again.';
                    });
                  }
                },
                child: const Text('Register'),
              ),
              TextButton(
                onPressed: () async {
                  final email = _emailController.text;
                  if (email.isEmpty) {
                    setState(() {
                      _errorMessage = 'Please enter your email to reset your password.';
                    });
                    return;
                  }
                  await _authService.sendPasswordResetEmail(email);
                  setState(() {
                    _errorMessage = 'Password reset email sent to $email';
                  });
                },
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
