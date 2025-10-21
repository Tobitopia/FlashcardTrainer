import 'package:flutter/material.dart';
import 'package:projects/services/auth_service.dart'; // Import your AuthService

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Create an instance of the AuthService
  final AuthService _authService = AuthService();

  // Create TextEditingControllers to get the text from the fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Remember to dispose of controllers when the widget is removed
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
        title: const Text('Login or Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController, // Attach the controller
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController, // Attach the controller
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async { // Make the function async
                final email = _emailController.text;
                final password = _passwordController.text;
                final userCredential = await _authService.signInWithEmailAndPassword(email, password);
                if (userCredential != null) {
                  print('Login Successful: ${userCredential.user?.email}');
                  // TODO: Navigate to the main app screen
                } else {
                  print('Login Failed');
                  // TODO: Show an error message to the user
                }
              },
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () async { // Make the function async
                final email = _emailController.text;
                final password = _passwordController.text;
                final userCredential = await _authService.createUserWithEmailAndPassword(email, password);
                if (userCredential != null) {
                  print('Registration Successful: ${userCredential.user?.email}');
                  // TODO: Navigate to the main app screen
                } else {
                  print('Registration Failed');
                  // TODO: Show an error message to the user
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
