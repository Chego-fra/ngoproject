import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up with email & password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print('Registration Error: $e');
      return null;
    }
  }

  // Sign in with email & password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Auth state changes
  Stream<User?> get userChanges => _auth.authStateChanges();
}
