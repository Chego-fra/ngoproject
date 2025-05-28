import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'event_form_screen.dart';
import 'volunteer_application_screen.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    final organizerId = user.uid;

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
          stream: FirebaseFirestore.instance
              .collection('events')
              .where('organizerId', isEqualTo: organizerId)
              .orderBy('date', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Something went wrong.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final events = snapshot.data?.docs ?? [];

            return ListView.builder(
              padding: const EdgeInsets.only(top: 10, bottom: 80),
              itemCount: events.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                    child: Text(
                      'My Events',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }

                final data = events[index - 1].data() as Map<String, dynamic>;
                final docId = events[index - 1].id;

                return Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  child: ListTile(
                    title: Text(
                      data['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat.yMMMEd().format((data['date'] as Timestamp).toDate()),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EventFormScreen(eventId: docId)),
                          );
                        } else if (value == 'delete') {
                          FirebaseFirestore.instance.collection('events').doc(docId).delete();
                        } else if (value == 'volunteers') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VolunteerApplicantsScreen(eventId: docId)),
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                        PopupMenuItem(value: 'volunteers', child: Text('Applicants')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF185a9d),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
