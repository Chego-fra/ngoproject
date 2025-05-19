import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class ResetPasswordScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Enter your email'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _resetPassword(context),
              child: Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetPassword(BuildContext context) async {
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}