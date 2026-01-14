import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email & password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      // You can add more specific error handling here later
      print('Failed to sign in: ${e.message}');
      return null;
    }
  }

  // Register with email & password
  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Failed to register: ${e.message}');
      return null;
    }
  }
  
  // Forgot password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Failed to send password reset email: ${e.message}');
    }
  }


  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
