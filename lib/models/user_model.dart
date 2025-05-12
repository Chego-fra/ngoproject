class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'volunteer', 'ngo', or 'admin'
  final String? phone;
  final String? profileImageUrl;
  final int totalHours; // for volunteers
  final List<String> badges;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImageUrl,
    this.totalHours = 0,
    this.badges = const [],
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'volunteer',
      phone: data['phone'],
      profileImageUrl: data['profileImageUrl'],
      totalHours: data['totalHours'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'totalHours': totalHours,
      'badges': badges,
    };
  }
}
