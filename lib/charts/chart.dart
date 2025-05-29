import 'package:flutter/material.dart';
import 'package:localloop/screens/admin/role_count.dart';
import 'chart_bar.dart';

class Chart extends StatelessWidget {
  const Chart({super.key, required this.roleCounts});

  final List<RoleCount> roleCounts;

  double get maxRoleCount {
    return roleCounts.map((rc) => rc.count).fold(0, (prev, e) => e > prev ? e : prev).toDouble();
  }

  Color getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.yellow;
      case 'ngo':
        return Colors.greenAccent;
      case 'voluteer':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.primary.withOpacity(0.0),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ),
      ),
      child: Column(
        children: [
          // Chart Bars
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: roleCounts.map((role) {
                final fill = role.count == 0 ? 0.0 : role.count / maxRoleCount;
                final color = getRoleColor(role.role);
                return ChartBar(fill: fill, color: color, count: role.count);
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Labels
          Row(
            children: roleCounts.map((role) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    role.role.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getRoleColor(role.role),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
