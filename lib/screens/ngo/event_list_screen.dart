import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this dependency in pubspec.yaml

import 'event_form_screen.dart';
import 'volunteer_application_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showEventDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        final date = (data['date'] as Timestamp).toDate();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(data['title'] ?? 'No Title'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("Description", data['description']),
                _buildDetailRow("Location", data['location']),
                _buildDetailRow("Date", DateFormat.yMMMd().format(date)),
                _buildDetailRow("Max Volunteers", '${data['maxVolunteers'] ?? 50}'),
                _buildDetailRow("Duration (hrs)", '${data['duration'] ?? 0}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Close"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '')),
        ],
      ),
    );
  }

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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by event name',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('organizerId', isEqualTo: organizerId)
                    .orderBy('date', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
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

                  final filteredEvents = events.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = (data['title'] as String).toLowerCase();
                    return title.contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 0, bottom: 80),
                    itemCount: filteredEvents.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
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

                      final data =
                          filteredEvents[index - 1].data() as Map<String, dynamic>;
                      final docId = filteredEvents[index - 1].id;

                      return Card(
                        color: Colors.white.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 4,
                        child: ListTile(
                          title: Text(
                            data['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            DateFormat.yMMMEd()
                                .format((data['date'] as Timestamp).toDate()),
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye,
                                    color: Colors.blueAccent),
                                onPressed: () => _showEventDetails(data),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            EventFormScreen(eventId: docId),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(docId)
                                        .delete();
                                  } else if (value == 'volunteers') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            VolunteerApplicantsScreen(eventId: docId),
                                      ),
                                    );
                                  } else if (value == 'ratings') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EventRatingScreen(eventId: docId),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                  PopupMenuItem(
                                      value: 'volunteers',
                                      child: Text('Applicants')),
                                  PopupMenuItem(
                                      value: 'ratings',
                                      child: Text('View Ratings')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
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

// NEW: EventRatingScreen showing pie chart of ratings

class EventRatingScreen extends StatelessWidget {
  final String eventId;
  const EventRatingScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Ratings')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .collection('ratings')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No ratings yet'));
          }

          final ratingsDocs = snapshot.data!.docs;

          // Count how many of each rating (1 to 5)
          Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          for (var doc in ratingsDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final rating = (data['rating'] ?? 0) as int;
            if (rating >= 1 && rating <= 5) {
              ratingCounts[rating] = ratingCounts[rating]! + 1;
            }
          }

          final totalRatings = ratingCounts.values.fold(0, (a, b) => a + b);
          final averageRating = ratingCounts.entries
                  .map((e) => e.key * e.value)
                  .fold(0, (a, b) => a + b) /
              totalRatings;

          final List<PieChartSectionData> sections = [];
          ratingCounts.forEach((star, count) {
            if (count > 0) {
              final double percentage = (count / totalRatings) * 100;
              sections.add(
                PieChartSectionData(
                  value: count.toDouble(),
                  title: '$star ★\n${percentage.toStringAsFixed(1)}%',
                  color: _starColor(star),
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.55,
                ),
              );
            }
          });

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Average Rating: ${averageRating.toStringAsFixed(2)} / 5',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: ratingCounts.entries.map((entry) {
                      return ListTile(
                        leading: Icon(Icons.star, color: _starColor(entry.key)),
                        title: Text('${entry.key} star'),
                        trailing: Text('${entry.value} votes'),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _starColor(int star) {
    switch (star) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
