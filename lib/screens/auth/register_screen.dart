import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final String defaultRole = 'voluteer';


  Future<void> registerUser() async {
    try {
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      await userCred.user!.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
        'email': emailCtrl.text.trim(),
        'role': defaultRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent. Please verify your email before logging in.')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Register failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.purpleAccent, Colors.deepPurple]),
        ),
        child: Center(
          child: Card(
            elevation: 10,
            margin: const EdgeInsets.symmetric(horizontal: 30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Register', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                  const SizedBox(height: 16),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: registerUser,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Register'),
                  ),
                  TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Go back to login screen
                  },
                  child: const Text("Already have an account? Login"),
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
