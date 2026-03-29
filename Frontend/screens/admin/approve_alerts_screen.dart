import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/public_alert_provider.dart';
import '../../models/public_alert.dart';

class ApproveAlertsScreen extends StatefulWidget {
  const ApproveAlertsScreen({super.key});

  @override
  State<ApproveAlertsScreen> createState() => _ApproveAlertsScreenState();
}

class _ApproveAlertsScreenState extends State<ApproveAlertsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PublicAlertProvider>().fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final pap = context.watch<PublicAlertProvider>();
    final pending = pap.allAlerts
        .where((a) => a.approvalStatus == 'Pending')
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Approve Alerts')),
      body: pap.loading
          ? const Center(child: CircularProgressIndicator())
          : pending.isEmpty
          ? const Center(child: Text('No pending alerts'))
          : RefreshIndicator(
              onRefresh: () => pap.fetchAll(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: pending.length,
                itemBuilder: (_, i) => _AlertReviewCard(alert: pending[i]),
              ),
            ),
    );
  }
}

class _AlertReviewCard extends StatelessWidget {
  final PublicAlert alert;
  const _AlertReviewCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final pap = context.read<PublicAlertProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const Spacer(),
                if (alert.anonymous)
                  const Chip(
                    label: Text('Anonymous', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert.description, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () => pap.review(alert.id, 'rejected'),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => pap.review(alert.id, 'approved'),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
