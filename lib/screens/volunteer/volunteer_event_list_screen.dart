import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VolunteerEventListScreen extends StatefulWidget {
  const VolunteerEventListScreen({super.key});

  @override
  State<VolunteerEventListScreen> createState() => _VolunteerEventListScreenState();
}

class _VolunteerEventListScreenState extends State<VolunteerEventListScreen> {
  String _searchText = '';
  List<QueryDocumentSnapshot> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .orderBy('date')
        .get();

    setState(() {
      _allEvents = snapshot.docs;
      _isLoading = false;
    });
  }

  Future<void> _applyToEvent(BuildContext context, String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final applications = FirebaseFirestore.instance.collection('event_applications');

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
    final filteredEvents = _allEvents.where((doc) {
      final title = (doc['title'] as String).toLowerCase();
      return title.contains(_searchText.toLowerCase());
    }).toList();

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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : ListView.builder(
                padding: const EdgeInsets.only(top: 10, bottom: 80),
                itemCount: filteredEvents.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                      child: Text(
                        'Available Events',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by event name...',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchText = value);
                        },
                      ),
                    );
                  }

                  final doc = filteredEvents[index - 2];
                  final data = doc.data() as Map<String, dynamic>;
                  final eventId = doc.id;

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
                          backgroundColor: const Color(0xFF43cea2),
                        ),
                        child: const Text("Register", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
