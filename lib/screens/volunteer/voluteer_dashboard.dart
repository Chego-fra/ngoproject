import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localloop/screens/volunteer/volunteer_event_list_screen.dart';

class VolunteerHome extends StatelessWidget {
  const VolunteerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(title: const Text("Volunteer Home"),
      backgroundColor: Color(0xFF43cea2),
      elevation: 0,
      actions:[
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacementNamed('/login');
      },
    ),
  ]
      
      
      ),
       body: VolunteerEventListScreen(),
    );
  }
}