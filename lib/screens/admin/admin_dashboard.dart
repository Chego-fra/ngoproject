import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:localloop/screens/admin/%20manage_users_screen.dart';
import 'package:localloop/screens/admin/role_chart_screen.dart';


class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_AdminFeature> features = [
      _AdminFeature(
        title: 'Manage Users',
        icon: Icons.group,
        screen: const ManageUsersScreen(),
      ),
        _AdminFeature(
    title: 'User Role Stats',  // 👈 New chart feature
    icon: Icons.bar_chart,
    screen: const RoleChartScreen(),
  ),
      // Add more features/screens here
      // Example:
      // _AdminFeature(title: 'Reports', icon: Icons.insert_chart, screen: ReportsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: features.map((feature) {
            return _FeatureCard(feature: feature);
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminFeature {
  final String title;
  final IconData icon;
  final Widget screen;

  _AdminFeature({required this.title, required this.icon, required this.screen});
}

class _FeatureCard extends StatelessWidget {
  final _AdminFeature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => feature.screen),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(feature.icon, size: 40, color: Colors.blueAccent),
              const SizedBox(height: 12),
              Text(
                feature.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
