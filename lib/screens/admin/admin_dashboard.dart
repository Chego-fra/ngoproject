import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:localloop/charts/chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'role_count.dart';



class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  Future<void> updateUserRole(String userId, String newRole) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'role': newRole,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Role updated to $newRole')),
    );
  }

  Future<void> deleteUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User deleted')),
    );
  }

  List<RoleCount> computeRoleCounts(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> roleMap = {
      'admin': 0,
      'ngo': 0,
      'voluteer': 0, // typo preserved
    };

    for (final doc in docs) {
      final role = doc['role'] as String;
      if (roleMap.containsKey(role)) {
        roleMap[role] = roleMap[role]! + 1;
      }
    }

    return roleMap.entries
        .map((e) => RoleCount(role: e.key, count: e.value))
        .toList();
  }

  Future<void> generatePdfReport() async {
    final pdf = pw.Document();

    // Fetch users from Firestore
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    // Create table rows with email and role
    final rows = snapshot.docs.map((doc) {
      final email = doc['email'] ?? 'N/A';
      final role = doc['role'] ?? 'N/A';
      return [email, role];
    }).toList();

    // Add content to PDF
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Users Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Email', 'Role'],
                data: rows,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(8),
              ),
            ],
          );
        },
      ),
    );

    // Open print/save dialog
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF43cea2),
        elevation: 0,
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Generate PDF Report',
            onPressed: generatePdfReport,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 70, 12, 12),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!.docs;
            final roleCounts = computeRoleCounts(users);

            // Apply search filtering
            final filteredUsers = users.where((user) {
              final email = (user['email'] as String).toLowerCase();
              final role = (user['role'] as String).toLowerCase();
              return email.contains(searchQuery) || role.contains(searchQuery);
            }).toList();

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by email or role',
                      fillColor: Colors.white.withOpacity(0.2),
                      filled: true,
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      hintStyle: const TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),

                // Live Chart
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Chart(roleCounts: roleCounts),
                ),
                const SizedBox(height: 20),

                // Users List
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final email = user['email'];
                      final role = user['role'];
                      final userId = user.id;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: Slidable(
                          key: ValueKey(userId),
                          endActionPane: ActionPane(
                            motion: const DrawerMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (_) => deleteUser(userId),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'Delete',
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4), width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              title: Text(
                                email,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Role: $role',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: DropdownButton<String>(
                                value: role,
                                dropdownColor: Colors.deepPurple,
                                iconEnabledColor: Colors.white,
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'voluteer', child: Text('voluteer')),
                                  DropdownMenuItem(value: 'ngo', child: Text('NGO')),
                                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                ],
                                onChanged: (newRole) {
                                  if (newRole != null && newRole != role) {
                                    updateUserRole(userId, newRole);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
