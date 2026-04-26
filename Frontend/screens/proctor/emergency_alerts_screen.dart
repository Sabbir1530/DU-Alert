import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../providers/emergency_provider.dart';
import '../../models/emergency_alert.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class EmergencyAlertsScreen extends StatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  State<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    context.read<EmergencyProvider>().fetchAll();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        context.read<EmergencyProvider>().fetchAll();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
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

  Future<({double? lat, double? lon})> _getResponderLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return (lat: null, lon: null);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      return (lat: position.latitude, lon: position.longitude);
    } catch (_) {
      return (lat: null, lon: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ep = context.read<EmergencyProvider>();
    final auth = context.watch<AuthProvider>();
    final studentName = alert.student?['full_name'] ?? 'Unknown';
    final phone = alert.student?['phone'] ?? '';
    final acknowledgedByName =
        alert.acknowledgedByName ?? alert.acknowledgedBy?['full_name'];
    final myUserId = auth.user?.id;
    final isAcknowledgedByMe =
        myUserId != null && alert.acknowledgedByUserId == myUserId;

    final statusText = switch (alert.status) {
      'active' => 'Pending Response',
      'acknowledged' when (acknowledgedByName ?? '').isNotEmpty =>
        'Acknowledged by $acknowledgedByName',
      'acknowledged' => 'Already Acknowledged',
      'resolved' => 'Resolved',
      _ => alert.status,
    };

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
                    statusText,
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
            if (alert.distanceInKm != null)
              Text(
                'Responder Distance: ${alert.distanceInKm!.toStringAsFixed(1)} km',
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
                      onPressed: () async {
                        final coords = await _getResponderLocation();
                        final ok = await ep.updateStatus(
                          alert.id,
                          'acknowledged',
                          responderLatitude: coords.lat,
                          responderLongitude: coords.lon,
                        );
                        if (!context.mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ep.error ??
                                    'Alert already acknowledged by another responder.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAcknowledgedByMe
                          ? 'You acknowledged this alert.'
                          : 'Already acknowledged by ${acknowledgedByName ?? 'another responder'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => ep.updateStatus(alert.id, 'resolved'),
                    child: const Text('Mark Resolved'),
                  ),
                ],
              ),
            if (alert.status == 'resolved')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Resolved',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
