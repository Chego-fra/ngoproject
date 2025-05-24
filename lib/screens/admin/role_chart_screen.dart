import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localloop/charts/chart.dart';


import 'role_count.dart';

class RoleChartScreen extends StatefulWidget {
  const RoleChartScreen({super.key});

  @override
  State<RoleChartScreen> createState() => _RoleChartScreenState();
}

class _RoleChartScreenState extends State<RoleChartScreen> {
  Future<List<RoleCount>> fetchRoleCounts() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final Map<String, int> roleMap = {
      'admin': 0,
      'ngo': 0,
      'volunteer': 0,
    };

    for (final doc in snapshot.docs) {
      final role = doc['role'] as String;
      if (roleMap.containsKey(role)) {
        roleMap[role] = roleMap[role]! + 1;
      }
    }

    return roleMap.entries.map((e) => RoleCount(role: e.key, count: e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Roles Chart")),
      body: FutureBuilder<List<RoleCount>>(
        future: fetchRoleCounts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Chart(roleCounts: snapshot.data!);
        },
      ),
    );
  }
}
