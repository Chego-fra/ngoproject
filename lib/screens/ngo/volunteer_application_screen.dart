import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerApplicantsScreen extends StatelessWidget {
  final String eventId;

  const VolunteerApplicantsScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final applicationsRef = FirebaseFirestore.instance.collection('event_applications');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Applicants'),
        backgroundColor: const Color(0xFF43cea2),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: applicationsRef.where('eventId', isEqualTo: eventId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Something went wrong', style: TextStyle(color: Colors.white)),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final apps = snapshot.data!.docs;

            if (apps.isEmpty) {
              return const Center(
                child: Text('No applications yet.', style: TextStyle(color: Colors.white)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final data = apps[index].data() as Map<String, dynamic>;
                final docId = apps[index].id;
                final status = data['status'] ?? 'pending';

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(data['volunteerId']).get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Card(
                          child: ListTile(title: Text('Loading...')),
                        ),
                      );
                    }

                    final user = userSnapshot.data!;
                    final userData = user.data() as Map<String, dynamic>;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF43cea2),
                            child: Text(
                              userData['name']?.substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            userData['name'] ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Status: ${status.toUpperCase()}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _handleAction(value, docId, context),
                            itemBuilder: (context) => [
                              if (status != 'approved')
                                const PopupMenuItem(value: 'approve', child: Text('Approve')),
                              if (status != 'rejected')
                                const PopupMenuItem(value: 'reject', child: Text('Reject')),
                              const PopupMenuItem(value: 'assign', child: Text('Assign Role')),
                            ],
                          ),
                        ),
                      ),
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

  void _handleAction(String action, String docId, BuildContext context) async {
    final appRef = FirebaseFirestore.instance.collection('event_applications').doc(docId);

    if (action == 'approve') {
      await appRef.update({'status': 'approved'});
    } else if (action == 'reject') {
      await appRef.update({'status': 'rejected'});
    } else if (action == 'assign') {
      final role = await _showAssignDialog(context);
      if (role != null && role.trim().isNotEmpty) {
        await appRef.update({'assignedRole': role});
      }
    }
  }

  Future<String?> _showAssignDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Role'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter role'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }
}
