import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../complaint/complaint_details_screen.dart';
import '../public_alert/public_alert_details_screen.dart';
import '../admin/approve_alerts_screen.dart';
import '../proctor/complaints_management_screen.dart';
import 'emergency_alert_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    provider.fetch();
    provider.startPolling();
  }

  @override
  void dispose() {
    context.read<NotificationProvider>().stopPolling();
    super.dispose();
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

  Future<void> _openNotification(
    BuildContext context,
    NotificationProvider np,
    AppNotification n,
  ) async {
    if (!n.isRead) {
      await np.markRead(n.id);
    }

    if (!context.mounted) {
      return;
    }

    final refType = n.referenceType ?? n.type;
    final refId = n.referenceId;
    final refSubId = n.referenceSubId;

    if (refType == 'complaint' || refType == 'complaint_status') {
      if (refId == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComplaintDetailsScreen(complaintId: refId),
        ),
      );
      return;
    }

    if (refType == 'public_alert' || refType == 'public_alert_comment') {
      if (refId == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PublicAlertDetailsScreen(
            alertId: refId,
            focusCommentId: refSubId,
          ),
        ),
      );
      return;
    }

    if (refType == 'complaint_review') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ComplaintsManagementScreen()),
      );
      return;
    }

    if (refType == 'status_review' || refType == 'complaint_status_review') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ComplaintsManagementScreen()),
      );
      return;
    }

    if (refType == 'public_alert_review') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ApproveAlertsScreen()),
      );
      return;
    }

    if (refType == 'emergency_alert') {
      if (refId == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmergencyAlertDetailsScreen(alertId: refId),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: np.notifications.any((n) => !n.isRead)
                ? () => np.markAllRead()
                : null,
          ),
        ],
      ),
      body: np.loading
          ? const Center(child: CircularProgressIndicator())
          : np.notifications.isEmpty
          ? const Center(child: Text('No notifications'))
          : RefreshIndicator(
              onRefresh: () => np.fetch(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: np.notifications.length,
                itemBuilder: (_, i) {
                  final n = np.notifications[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: n.isRead
                        ? null
                        : Colors.blue.withValues(alpha: 0.06),
                    child: ListTile(
                      onTap: () => _openNotification(context, np, n),
                      leading: CircleAvatar(
                        backgroundColor: n.isRead
                            ? Colors.grey.shade200
                            : Colors.blue.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.notifications,
                          color: n.isRead ? Colors.grey.shade700 : Colors.blue,
                        ),
                      ),
                      title: Text(
                        n.title,
                        style: TextStyle(
                          fontWeight: n.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(n.message),
                      trailing: Text(
                        _timeAgo(n.createdAt),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
