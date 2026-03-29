import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationProvider>().fetch();
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
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
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.notifications),
                      ),
                      title: Text(
                        n.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(n.message),
                      trailing: Text(
                        n.createdAt.split('T').first,
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
