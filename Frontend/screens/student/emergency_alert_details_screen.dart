import 'package:flutter/material.dart';
import '../../models/emergency_alert.dart';
import '../../services/api_service.dart';

class EmergencyAlertDetailsScreen extends StatefulWidget {
  final String alertId;

  const EmergencyAlertDetailsScreen({super.key, required this.alertId});

  @override
  State<EmergencyAlertDetailsScreen> createState() =>
      _EmergencyAlertDetailsScreenState();
}

class _EmergencyAlertDetailsScreenState
    extends State<EmergencyAlertDetailsScreen> {
  late Future<EmergencyAlert> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<EmergencyAlert> _load() async {
    final res = await ApiService.get('/emergency/${widget.alertId}');
    return EmergencyAlert.fromJson(res['alert'] as Map<String, dynamic>);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.red;
      case 'acknowledged':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusText(EmergencyAlert alert) {
    if (alert.status == 'active') return 'Pending Response';
    if (alert.status == 'acknowledged') {
      final by = alert.acknowledgedByName ?? alert.acknowledgedBy?['full_name'];
      if ((by ?? '').isNotEmpty) return 'Acknowledged by $by';
      return 'Already Acknowledged';
    }
    if (alert.status == 'resolved') return 'Resolved';
    return alert.status;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Alert Details')),
      body: FutureBuilder<EmergencyAlert>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Unable to load emergency alert details.',
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final alert = snapshot.data!;
          final student = alert.student;
          final statusColor = _statusColor(alert.status);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _load();
              });
              await _future;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
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
                                _statusText(alert),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Student: ${student?['full_name'] ?? 'Unknown'}'),
                        Text(
                          'Department: ${student?['department'] ?? 'Unknown'}',
                        ),
                        Text('Phone: ${student?['phone'] ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        Text(
                          'Location: ${alert.latitude.toStringAsFixed(6)}, ${alert.longitude.toStringAsFixed(6)}',
                        ),
                        if (alert.acknowledgedAt != null)
                          Text('Acknowledged At: ${alert.acknowledgedAt}'),
                        if (alert.distanceInKm != null)
                          Text(
                            'Responder Distance: ${alert.distanceInKm!.toStringAsFixed(1)} km',
                          ),
                        Text('Created At: ${alert.createdAt}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
