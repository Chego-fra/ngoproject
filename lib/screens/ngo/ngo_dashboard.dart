import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localloop/screens/ngo/event_list_screen.dart';


class NgoHome extends StatelessWidget {
  const NgoHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("NGO Home"),
        backgroundColor: Color(0xFF43cea2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // ignore: use_build_context_synchronously
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: EventListScreen(),  // Show events for this NGO
    );
  }
}
