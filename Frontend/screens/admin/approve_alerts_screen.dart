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

  Future<void> _rejectWithReason(BuildContext context) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Provide a brief reason for rejection',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    final pap = context.read<PublicAlertProvider>();
    await pap.review(alert.id, 'Rejected', rejectionReason: reason);
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alert Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: ${alert.category}'),
              const SizedBox(height: 6),
              Text('Status: ${alert.approvalStatus}'),
              const SizedBox(height: 6),
              Text('Anonymous: ${alert.anonymous ? 'Yes' : 'No'}'),
              const SizedBox(height: 6),
              Text('Created At: ${alert.createdAt}'),
              const SizedBox(height: 6),
              Text('Created By: ${alert.creator?['full_name'] ?? 'Unknown'}'),
              const SizedBox(height: 6),
              Text('Department: ${alert.creator?['department'] ?? 'N/A'}'),
              const SizedBox(height: 10),
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(alert.description),
              const SizedBox(height: 10),
              Text('Attachments: ${alert.media.length}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _showDetails(context),
              icon: const Icon(Icons.visibility),
              label: const Text('View Full Details'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () => _rejectWithReason(context),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () => pap.review(alert.id, 'Approved'),
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
