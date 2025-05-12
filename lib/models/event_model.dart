import 'package:cloud_firestore/cloud_firestore.dart';


class Event {
  final String id;
  final String title;
  final String description;
  final String organizerId;
  final DateTime date;
  final String location;
  final List<String> participantIds;
  final int maxVolunteers;
  final String? bannerImageUrl;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.organizerId,
    required this.date,
    required this.location,
    this.participantIds = const [],
    this.maxVolunteers = 50,
    this.bannerImageUrl,
  });

  factory Event.fromMap(Map<String, dynamic> data, String docId) {
    return Event(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      organizerId: data['organizerId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      maxVolunteers: data['maxVolunteers'] ?? 50,
      bannerImageUrl: data['bannerImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'organizerId': organizerId,
      'date': date,
      'location': location,
      'participantIds': participantIds,
      'maxVolunteers': maxVolunteers,
      'bannerImageUrl': bannerImageUrl,
    };
  }
}
