import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/emergency_provider.dart';
import '../../models/emergency_alert.dart';
import '../../config/theme.dart';

class EmergencyAlertsScreen extends StatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  State<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EmergencyProvider>().fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.watch<EmergencyProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Alerts')),
      body: ep.loading
          ? const Center(child: CircularProgressIndicator())
          : ep.alerts.isEmpty
          ? const Center(child: Text('No emergency alerts'))
          : RefreshIndicator(
              onRefresh: () => ep.fetchAll(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: ep.alerts.length,
                itemBuilder: (_, i) => _EmergencyCard(alert: ep.alerts[i]),
              ),
            ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final EmergencyAlert alert;
  const _EmergencyCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final ep = context.read<EmergencyProvider>();
    final studentName = alert.student?['full_name'] ?? 'Unknown';
    final phone = alert.student?['phone'] ?? '';

    Color statusColor;
    switch (alert.status) {
      case 'active':
        statusColor = AppTheme.danger;
        break;
      case 'acknowledged':
        statusColor = Colors.orange;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    studentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Phone: $phone'),
            Text(
              'Location: ${alert.latitude.toStringAsFixed(6)}, ${alert.longitude.toStringAsFixed(6)}',
            ),
            Text('Time: ${alert.createdAt.split('T').first}'),
            const SizedBox(height: 12),
            if (alert.status == 'active')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () =>
                          ep.updateStatus(alert.id, 'acknowledged'),
                      child: const Text('Acknowledge'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => ep.updateStatus(alert.id, 'resolved'),
                      child: const Text('Resolve'),
                    ),
                  ),
                ],
              ),
            if (alert.status == 'acknowledged')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => ep.updateStatus(alert.id, 'resolved'),
                  child: const Text('Mark Resolved'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
