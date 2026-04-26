import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/public_alert.dart';
import '../../providers/auth_provider.dart';
import '../../providers/public_alert_provider.dart';
import '../../widgets/alert_card.dart';

class PublicAlertFeedScreen extends StatefulWidget {
  const PublicAlertFeedScreen({super.key});

  @override
  State<PublicAlertFeedScreen> createState() => _PublicAlertFeedScreenState();
}

class _PublicAlertFeedScreenState extends State<PublicAlertFeedScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PublicAlertProvider>().fetchFeed(refresh: true);
    });

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final threshold = _scrollController.position.maxScrollExtent - 280;
      if (_scrollController.position.pixels >= threshold) {
        context.read<PublicAlertProvider>().fetchMoreFeed();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertsProvider = context.watch<PublicAlertProvider>();
    final auth = context.watch<AuthProvider>();

    final hasInitialLoading = alertsProvider.loading && alertsProvider.feed.isEmpty;
    final hasError = (alertsProvider.error ?? '').isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Public Safety Alerts')),
      body: hasInitialLoading
          ? const _FeedSkeletonList()
          : alertsProvider.feed.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(hasError ? alertsProvider.error! : 'No approved alerts yet'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => alertsProvider.fetchFeed(refresh: true),
                    child: const Text('Reload'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => alertsProvider.fetchFeed(refresh: true),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: alertsProvider.feed.length +
                    (alertsProvider.feedLoadingMore ? 1 : 0),
                itemBuilder: (_, index) {
                  if (index >= alertsProvider.feed.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final alert = alertsProvider.feed[index];
                  return AlertCard(
                    alert: alert,
                    currentUserId: auth.user?.id,
                    onReact: (type) => alertsProvider.reactToAlert(alert.id, type),
                    onRemoveReaction: () => alertsProvider.removeReaction(alert.id),
                    onAddComment: (text) =>
                        alertsProvider.addCommentToAlert(alert.id, text),
                    onDeleteComment: (commentId) => alertsProvider.deleteComment(
                      alertId: alert.id,
                      commentId: commentId,
                    ),
                    onLoadComments: () => _loadCommentsForAlert(
                      alertsProvider,
                      alert,
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<List<PublicAlertComment>> _loadCommentsForAlert(
    PublicAlertProvider provider,
    PublicAlert alert,
  ) async {
    final comments = await provider.fetchComments(alert.id, page: 1, limit: 50);
    return comments;
  }
}

class _FeedSkeletonList extends StatelessWidget {
  const _FeedSkeletonList();

  Widget _line(double width) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _card() {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(120),
                    const SizedBox(height: 8),
                    _line(80),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _line(double.infinity),
            const SizedBox(height: 8),
            _line(double.infinity),
            const SizedBox(height: 8),
            _line(220),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 4,
      itemBuilder: (_, _) => _card(),
    );
  }
}
