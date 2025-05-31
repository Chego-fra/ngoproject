import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  Future<void> updateUserRole(String userId, String newRole) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'role': newRole,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Role updated to $newRole')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final email = user['email'];
              final role = user['role'];
              final userId = user.id;

              return ListTile(
                title: Text(email),
                subtitle: Text('Role: $role'),
                trailing: DropdownButton<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'volunteer', child: Text('volunteer')),
                    DropdownMenuItem(value: 'ngo', child: Text('Ngo')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (newRole) {
                    if (newRole != null) {
                      updateUserRole(userId, newRole);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
