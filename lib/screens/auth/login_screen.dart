import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localloop/screens/admin/admin_dashboard.dart';
import 'package:localloop/screens/auth/register_screen.dart';
import 'package:localloop/screens/auth/reset_password_screen.dart';
import 'package:localloop/screens/ngo/ngo_dashboard.dart';
import 'package:localloop/screens/volunteer/voluteer_dashboard.dart';


class LoginScreen extends StatelessWidget {
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  LoginScreen({super.key});

  void login(BuildContext context) async {
    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );


// Check if email is verified
    if (!(userCred.user?.emailVerified ?? false)) {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your email before logging in.')),
      );
      return;
    }



      final roleDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCred.user!.uid)
              .get();

      final role = roleDoc.data()?['role'];

    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHome()),
      );
    } else if (role == 'ngo') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NgoHome()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VolunteerHome()), // fixed typo
      );
    }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purpleAccent, Colors.deepPurple],
          ),
        ),

        child: Center(
          child: Card(
            elevation: 10,
            margin: const EdgeInsets.symmetric(horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Login',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => login(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text('No account? Register'),
                  ),
                  const SizedBox(height: 7),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResetPasswordScreen(),
                        ),
                      ); // Navigate to Reset Password Screen
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
