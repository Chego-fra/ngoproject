import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VolunteerEventListScreen extends StatelessWidget {
  const VolunteerEventListScreen({super.key});

  Future<void> _applyToEvent(BuildContext context, String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final applications = FirebaseFirestore.instance.collection('event_applications');

    // Check if user has already applied
    final existing = await applications
        .where('eventId', isEqualTo: eventId)
        .where('volunteerId', isEqualTo: user.uid)
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already applied to this event')),
      );
      return;
    }

    await applications.add({
      'eventId': eventId,
      'volunteerId': user.uid,
      'status': 'pending',
      'appliedAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application sent')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = FirebaseFirestore.instance
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: events,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final eventDocs = snapshot.data?.docs ?? [];

            return ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 80),
              itemCount: eventDocs.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                    child: Text(
                      'Available Events',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final data = eventDocs[index - 1].data() as Map<String, dynamic>;
                final eventId = eventDocs[index - 1].id;

                return Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  child: ListTile(
                    title: Text(data['title']),
                    subtitle: Text(
                      '${DateFormat.yMMMEd().format((data['date'] as Timestamp).toDate())} • ${data['location']}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _applyToEvent(context, eventId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF185a9d),
                      ),
                      child: const Text("Apply", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
