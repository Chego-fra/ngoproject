import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PendingApplicationsScreen extends StatefulWidget {
  const PendingApplicationsScreen({super.key});

  @override
  State<PendingApplicationsScreen> createState() => _PendingApplicationsScreenState();
}

class _PendingApplicationsScreenState extends State<PendingApplicationsScreen> {
  late Future<Map<String, String>> _eventIdToTitleMapFuture;
  final Map<String, String> _volunteerIdToName = {}; // cache

  @override
  void initState() {
    super.initState();
    _eventIdToTitleMapFuture = _loadEventTitles();
  }

  Future<Map<String, String>> _loadEventTitles() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final query = await FirebaseFirestore.instance
        .collection('events')
        .where('organizerId', isEqualTo: user.uid)
        .get();

    return {
      for (var doc in query.docs) doc.id: doc['title'] ?? 'Untitled',
    };
  }

  Future<String> _getVolunteerName(String volunteerId) async {
    if (_volunteerIdToName.containsKey(volunteerId)) {
      return _volunteerIdToName[volunteerId]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(volunteerId)
          .get();

      final name = doc.data()?['name'] ?? 'Unnamed Volunteer';
      _volunteerIdToName[volunteerId] = name;
      return name;
    } catch (e) {
      return 'Unnamed Volunteer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pending Applications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<Map<String, String>>(
          future: _eventIdToTitleMapFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No events found for this user.', style: TextStyle(color: Colors.white)),
              );
            }

            final eventMap = snapshot.data!;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('event_applications')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, appSnapshot) {
                if (appSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (!appSnapshot.hasData || appSnapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No pending applications.', style: TextStyle(color: Colors.white)),
                  );
                }

                final filtered = appSnapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return eventMap.containsKey(data['eventId']);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No pending applications for your events.', style: TextStyle(color: Colors.white)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 100, bottom: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final eventId = data['eventId'];
                    final volunteerId = data['volunteerId'];
                    final eventTitle = eventMap[eventId] ?? 'Unknown Event';

                    return FutureBuilder<String>(
                      future: _getVolunteerName(volunteerId),
                      builder: (context, nameSnapshot) {
                        final volunteerName = nameSnapshot.data ?? 'Unnamed Volunteer';

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Card(
                            color: Colors.white.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                            child: ListTile(
                              leading: const Icon(Icons.person, color: Colors.teal),
                              title: Text(
                                volunteerName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Event: $eventTitle'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Application'),
                                      content: const Text('Are you sure you want to delete this application?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('event_applications')
                                        .doc(docId)
                                        .delete();
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
