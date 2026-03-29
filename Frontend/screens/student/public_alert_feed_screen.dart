import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/public_alert_provider.dart';
import '../../models/public_alert.dart';
import '../../config/theme.dart';

class PublicAlertFeedScreen extends StatefulWidget {
  const PublicAlertFeedScreen({super.key});

  @override
  State<PublicAlertFeedScreen> createState() => _PublicAlertFeedScreenState();
}

class _PublicAlertFeedScreenState extends State<PublicAlertFeedScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PublicAlertProvider>().fetchFeed();
  }

  @override
  Widget build(BuildContext context) {
    final pa = context.watch<PublicAlertProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Public Safety Alerts')),
      body: pa.loading
          ? const Center(child: CircularProgressIndicator())
          : pa.feed.isEmpty
          ? const Center(child: Text('No alerts yet'))
          : RefreshIndicator(
              onRefresh: () => pa.fetchFeed(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: pa.feed.length,
                itemBuilder: (_, i) => _AlertCard(alert: pa.feed[i]),
              ),
            ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final PublicAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final creator = alert.anonymous || alert.creator == null
        ? 'Anonymous'
        : alert.creator!['full_name'] ?? 'Unknown';

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
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.category,
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  alert.createdAt.split('T').first,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(alert.description, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 8),
            Text(
              'Posted by: $creator',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            if (alert.media.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16),
                    Text('${alert.media.length} attachment(s)'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
