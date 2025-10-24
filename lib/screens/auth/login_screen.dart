import 'package:flutter/material.dart';
import 'package:projects/services/auth_service.dart'; // Import your AuthService

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage; // State variable for error messages
  bool _isPasswordVisible = false; // State variable for password visibility

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Removed title here to make space for the main title in the body
      ),
      body: Padding(
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
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isPasswordVisible, // Use the state variable here
            ),
            if (_errorMessage != null) // Display error message if present
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
                  _errorMessage = null; // Clear previous error
                });
                final email = _emailController.text;
                final password = _passwordController.text;
                final userCredential = await _authService.signInWithEmailAndPassword(email, password);
                if (userCredential != null) {
                  print('Login Successful: ${userCredential.user?.email}');
                  // TODO: Navigate to the main app screen
                } else {
                  setState(() {
                    _errorMessage = 'Login failed. Please check your credentials.';
                  });
                  print('Login Failed');
                }
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _errorMessage = null; // Clear previous error
                });
                final email = _emailController.text;
                final password = _passwordController.text;
                final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
                if (userCredential != null) {
                  print('Registration Successful: ${userCredential.user?.email}');
                  // TODO: Navigate to the main app screen
                } else {
                  setState(() {
                    _errorMessage = 'Registration failed. Please try again.';
                  });
                  print('Registration Failed');
                }
              },
              child: const Text('Register'),
            )
          ],
        ),
      ),
    );
  }
}
