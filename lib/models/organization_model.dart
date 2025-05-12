class Organization {
  final String id;
  final String name;
  final String email;
  final String description;
  final String phone;
  final String address;
  final String? logoUrl;
  final List<String> eventIds;

  Organization({
    required this.id,
    required this.name,
    required this.email,
    required this.description,
    required this.phone,
    required this.address,
    this.logoUrl,
    this.eventIds = const [],
  });

  factory Organization.fromMap(Map<String, dynamic> data, String docId) {
    return Organization(
      id: docId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      description: data['description'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      logoUrl: data['logoUrl'],
      eventIds: List<String>.from(data['eventIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'description': description,
      'phone': phone,
      'address': address,
      'logoUrl': logoUrl,
      'eventIds': eventIds,
    };
  }
}
