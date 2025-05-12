import 'package:cloud_firestore/cloud_firestore.dart';

class Certificate {
  final String id;
  final String userId;
  final String eventId;
  final String eventTitle;
  final DateTime issueDate;
  final int hoursCompleted;
  final String? downloadUrl;

  Certificate({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.eventTitle,
    required this.issueDate,
    required this.hoursCompleted,
    this.downloadUrl,
  });

  factory Certificate.fromMap(Map<String, dynamic> data, String docId) {
    return Certificate(
      id: docId,
      userId: data['userId'] ?? '',
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      issueDate: (data['issueDate'] as Timestamp).toDate(),
      hoursCompleted: data['hoursCompleted'] ?? 0,
      downloadUrl: data['downloadUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'issueDate': issueDate,
      'hoursCompleted': hoursCompleted,
      'downloadUrl': downloadUrl,
    };
  }
}
