import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EventRatingScreen extends StatelessWidget {
  final String eventId;
  const EventRatingScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Ratings'),
        backgroundColor: const Color(0xFF185a9d),
        foregroundColor: Colors.white,
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
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .collection('ratings')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No ratings yet',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              );
            }

            final ratingsDocs = snapshot.data!.docs;

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
                    title: '$star★\n${percentage.toStringAsFixed(1)}%',
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Average Rating',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${averageRating.toStringAsFixed(2)} / 5.0',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rating Breakdown',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...ratingCounts.entries.map((entry) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.star,
                                      color: _starColor(entry.key)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${entry.key} Star',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${entry.value} votes',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
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
        return Colors.amber.shade700;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
