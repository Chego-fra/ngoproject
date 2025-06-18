import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:localloop/screens/ngo/event_list_screen.dart';
import 'package:localloop/screens/ngo/pending_applications_screen.dart';

class NgoHome extends StatefulWidget {
  const NgoHome({super.key});

  @override
  State<NgoHome> createState() => _NgoHomeState();
}

class _NgoHomeState extends State<NgoHome> {
  int _pendingApplicationCount = 0;
  late StreamSubscription _subscription;
  List<String> _ngoEventIds = [];

  @override
  void initState() {
    super.initState();
    _loadNgoEventsAndListen();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _loadNgoEventsAndListen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Step 1: Get list of event IDs created by this NGO
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('ngoId', isEqualTo: user.uid)
        .get();

    _ngoEventIds = eventsSnapshot.docs.map((doc) => doc.id).toList();

    // Step 2: Now listen to pending applications
    _subscription = FirebaseFirestore.instance
        .collection('event_applications')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      int count = 0;

      for (final doc in snapshot.docs) {
        final eventId = doc['eventId'];
        if (_ngoEventIds.contains(eventId)) {
          count++;
        }
      }

      setState(() {
        _pendingApplicationCount = count;
      });
    });
  }

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
        backgroundColor: const Color(0xFF43cea2),
        elevation: 0,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PendingApplicationsScreen(),
                    ),
                  );
                },
              ),
              if (_pendingApplicationCount > 0)
                Positioned(
                  right: 10,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_pendingApplicationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: const EventListScreen(),
    );
  }
}
