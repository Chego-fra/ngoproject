import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class VolunteerEventListScreen extends StatefulWidget {
  const VolunteerEventListScreen({super.key});

  @override
  State<VolunteerEventListScreen> createState() =>
      _VolunteerEventListScreenState();
}

class _VolunteerEventListScreenState extends State<VolunteerEventListScreen> {
  String _searchText = '';
  List<QueryDocumentSnapshot> _allEvents = [];
  bool _isLoading = true;
  int _unseenNotificationCount = 0;
  late final StreamSubscription _notificationSubscription;
  final Set<String> _expandedCards = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .orderBy('date', descending: true)
              .get();

      setState(() {
        _allEvents = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() => _isLoading = false);
    }
  }

  void _listenToNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          setState(() {
            _unseenNotificationCount = snapshot.docs.length;
          });
        });
  }

  Future<void> sendPushMessage(
    String token,
    String title,
    String body, {
    String? eventId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'title': title,
          'body': body,
          if (eventId != null) 'eventId': eventId,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to send push notification: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print("Error sending push notification: $e");
    }
  }

  Future<void> _applyToEvent(BuildContext context, String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final applications = FirebaseFirestore.instance.collection(
      'event_applications',
    );

    final existing =
        await applications
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

    final eventDoc =
        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .get();
    if (!eventDoc.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event not found')));
      return;
    }

    final eventData = eventDoc.data()!;
    final organizerId = eventData['organizerId'] as String;
    final eventTitle = eventData['title'] as String;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(organizerId)
        .collection('notifications')
        .add({
          'message': 'A volunteer has registered for your event "$eventTitle".',
          'seen': false,
          'timestamp': Timestamp.now(),
          'eventId': eventId,
          'volunteerId': user.uid,
        });

    final organizerDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(organizerId)
            .get();
    final fcmToken = organizerDoc.data()?['fcmToken'] ?? '';

    if (fcmToken.isNotEmpty) {
      await sendPushMessage(
        fcmToken,
        'New Volunteer Application',
        'Someone registered for "$eventTitle".',
        eventId: eventId,
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Application sent')));
  }

  Widget starRating({
    required int rating,
    required ValueChanged<int>? onRatingChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap:
              onRatingChanged != null ? () => onRatingChanged(index + 1) : null,
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 28,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents =
        _allEvents.where((doc) {
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
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 80),
                  itemCount: filteredEvents.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Available Events',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_unseenNotificationCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_unseenNotificationCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    } else if (index == 1) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8,
                        ),
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
                    final isExpanded = _expandedCards.contains(eventId);

                    return GestureDetector(
                      onTap: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        final willExpand = !_expandedCards.contains(eventId);

                        if (user != null && willExpand) {
                          final notifications =
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('notifications')
                                  .where('eventId', isEqualTo: eventId)
                                  .where('seen', isEqualTo: false)
                                  .get();

                          final batch = FirebaseFirestore.instance.batch();
                          for (final doc in notifications.docs) {
                            batch.update(doc.reference, {'seen': true});
                          }
                          await batch.commit();
                        }

                        setState(() {
                          if (_expandedCards.contains(eventId)) {
                            _expandedCards.remove(eventId);
                          } else {
                            _expandedCards.add(eventId);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              Text(
                                data['description'] ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Date: ${DateFormat.yMMMd().format((data['date'] as Timestamp).toDate())}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed:
                                    () => _applyToEvent(context, eventId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF43cea2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Register'),
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder<DocumentSnapshot>(
                                future:
                                    FirebaseFirestore.instance
                                        .collection('events')
                                        .doc(eventId)
                                        .collection('ratings')
                                        .doc(
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                        )
                                        .get(),
                                builder: (context, snapshot) {
                                  int userRating = 0;
                                  if (snapshot.hasData &&
                                      snapshot.data!.exists) {
                                    final ratingData =
                                        snapshot.data!.data()
                                            as Map<String, dynamic>;
                                    userRating = ratingData['rating'] ?? 0;
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Your Rating:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      starRating(
                                        rating: userRating,
                                        onRatingChanged: (newRating) async {
                                          final userId =
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser!
                                                  .uid;
                                          await FirebaseFirestore.instance
                                              .collection('events')
                                              .doc(eventId)
                                              .collection('ratings')
                                              .doc(userId)
                                              .set({
                                                'rating': newRating,
                                                'ratedAt': Timestamp.now(),
                                              });
                                          setState(() {});
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      if (userRating > 0)
                                        StreamBuilder<QuerySnapshot>(
                                          stream:
                                              FirebaseFirestore.instance
                                                  .collection('events')
                                                  .doc(eventId)
                                                  .collection('ratings')
                                                  .snapshots(),
                                          builder: (context, ratingSnapshot) {
                                            if (!ratingSnapshot.hasData)
                                              return const SizedBox();

                                            final ratings =
                                                ratingSnapshot.data!.docs
                                                    .map(
                                                      (doc) =>
                                                          (doc.data()
                                                                  as Map<
                                                                    String,
                                                                    dynamic
                                                                  >)['rating']
                                                              as int,
                                                    )
                                                    .toList();

                                            if (ratings.isEmpty) {
                                              return const Text(
                                                'No ratings yet',
                                              );
                                            }

                                            final avgRating =
                                                ratings.reduce(
                                                  (a, b) => a + b,
                                                ) /
                                                ratings.length;

                                            return Row(
                                              children: [
                                                Text(
                                                  'Average Rating: ${avgRating.toStringAsFixed(1)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                starRating(
                                                  rating: avgRating.round(),
                                                  onRatingChanged: null,
                                                ),
                                              ],
                                            );
                                          },
                                        )
                                      else
                                        const Text(
                                          'Rate this event to see the average rating.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
