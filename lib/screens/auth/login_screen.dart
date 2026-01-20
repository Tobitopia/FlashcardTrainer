import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:projects/app/navigation.dart';
import 'package:projects/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isPasswordVisible = false;
  bool _isLogin = true; 
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in all fields.";
        _isLoading = false;
      });
      return;
    }

    try {
      dynamic userCredential;
      if (_isLogin) {
        userCredential = await _authService.signInWithEmailAndPassword(email, password);
      } else {
        userCredential = await _authService.createUserWithEmailAndPassword(email, password);
      }

      if (userCredential != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NavigationBarScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = _isLogin ? 'Login failed.' : 'Registration failed.';
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = "Please enter your email to reset password.";
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password reset email sent to $email")),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8146BD), Color(0xFFE0436B)],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                        errorBuilder: (c, e, s) => const Icon(Icons.psychology, size: 80, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'StepNote',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      'Build your repertoire',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    
                    // Glassy Form
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _isLogin ? 'Welcome Back' : 'Create Account',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(_emailController, 'Email', Icons.email_outlined),
                              const SizedBox(height: 15),
                              _buildTextField(
                                _passwordController, 
                                'Password', 
                                Icons.lock_outline, 
                                isPassword: true,
                              ),
                              if (_errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 15.0),
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF8146BD),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  ),
                                  onPressed: _isLoading ? null : _submit,
                                  child: _isLoading 
                                    ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8146BD))))
                                    : Text(_isLogin ? 'LOGIN' : 'REGISTER', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin ? "Don't have an account? Register" : "Already have an account? Login",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (_isLogin)
                      TextButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        child: const Text("Forgot Password?", style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white)),
      ),
    );
  }
}
