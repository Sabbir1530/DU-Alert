import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/public_alert.dart';
import '../../providers/public_alert_provider.dart';
import '../../widgets/media_viewer.dart';

class PublicAlertDetailsScreen extends StatefulWidget {
  final String alertId;
  final String? focusCommentId;

  const PublicAlertDetailsScreen({
    super.key,
    required this.alertId,
    this.focusCommentId,
  });

  @override
  State<PublicAlertDetailsScreen> createState() =>
      _PublicAlertDetailsScreenState();
}

class _PublicAlertDetailsScreenState extends State<PublicAlertDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PublicAlertProvider>().fetchById(widget.alertId);
    });
  }

  String _timeAgo(String raw) {
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return '${weeks}w ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months}mo ago';
    final years = (diff.inDays / 365).floor();
    return '${years}y ago';
  }

  Widget _statusChip(PublicAlert alert) {
    final status = alert.approvalStatus;
    Color color;
    if (status == 'Approved') {
      color = Colors.green;
    } else if (status == 'Rejected') {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }

  Widget _commentTile(PublicAlertComment comment, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? Colors.amber.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? Colors.amber : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.user?['full_name']?.toString() ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(comment.content),
          const SizedBox(height: 6),
          Text(
            _timeAgo(comment.createdAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PublicAlertProvider>();
    final alert = provider.alertById(widget.alertId);

    if (provider.loading && alert == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (alert == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alert Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.error ?? 'Could not load alert details'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => provider.fetchById(widget.alertId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final PublicAlertComment? highlighted = widget.focusCommentId == null
        ? null
        : alert.comments.firstWhere(
            (c) => c.id == widget.focusCommentId,
            orElse: () => PublicAlertComment(
              id: '',
              alertId: '',
              userId: '',
              content: '',
              createdAt: '',
            ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Alert Details')),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchById(widget.alertId),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
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
                        const SizedBox(width: 8),
                        _statusChip(alert),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.description,
                      style: const TextStyle(height: 1.4),
                    ),
                    MediaViewer(media: alert.media),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          _timeAgo(alert.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        if (alert.anonymous)
                          const Text(
                            'Anonymous',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                    if (alert.approvalStatus == 'Rejected' &&
                        (alert.rejectionReason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          'Rejection reason: ${alert.rejectionReason}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Comments',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (widget.focusCommentId != null &&
                highlighted?.id.isNotEmpty == true)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Highlighted comment',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  _commentTile(highlighted!, highlight: true),
                ],
              ),
            if (alert.comments.isEmpty)
              const Text('No comments yet')
            else
              ...alert.comments
                  .where((c) => c.id != highlighted?.id)
                  .map((c) => _commentTile(c)),
          ],
        ),
      ),
    );
  }
}
