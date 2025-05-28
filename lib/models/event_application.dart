class EventApplication {
  final String id;
  final String eventId;
  final String volunteerId;
  final String status; // 'pending', 'approved', 'rejected'
  final String? assignedRole;

  EventApplication({
    required this.id,
    required this.eventId,
    required this.volunteerId,
    this.status = 'pending',
    this.assignedRole,
  });

  factory EventApplication.fromMap(Map<String, dynamic> data, String docId) {
    return EventApplication(
      id: docId,
      eventId: data['eventId'],
      volunteerId: data['volunteerId'],
      status: data['status'] ?? 'pending',
      assignedRole: data['assignedRole'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'volunteerId': volunteerId,
      'status': status,
      'assignedRole': assignedRole,
    };
  }
}
