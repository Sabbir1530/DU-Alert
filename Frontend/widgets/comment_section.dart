import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/public_alert.dart';
import '../config/theme.dart';

typedef AddCommentCallback = Future<bool> Function(String content);
typedef DeleteCommentCallback = Future<bool> Function(String commentId);
typedef LoadCommentsCallback = Future<List<PublicAlertComment>> Function();

class CommentSection extends StatefulWidget {
  final String alertId;
  final List<PublicAlertComment> comments;
  final int commentCount;
  final String? currentUserId;
  final AddCommentCallback onAddComment;
  final DeleteCommentCallback onDeleteComment;
  final LoadCommentsCallback onLoadComments;

  const CommentSection({
    super.key,
    required this.alertId,
    required this.comments,
    required this.commentCount,
    required this.currentUserId,
    required this.onAddComment,
    required this.onDeleteComment,
    required this.onLoadComments,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _createdLabel(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw.split('T').first;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    final ok = await widget.onAddComment(text);
    if (!mounted) return;

    setState(() => _submitting = false);
    if (ok) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _openAllCommentsModal() async {
    List<PublicAlertComment> items = widget.comments;
    bool loading = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> loadFresh() async {
              setSheetState(() => loading = true);
              final fresh = await widget.onLoadComments();
              if (!ctx.mounted) return;
              setSheetState(() {
                items = fresh;
                loading = false;
              });
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Comments',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: loadFresh,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 420,
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : items.isEmpty
                          ? const Center(child: Text('No comments yet'))
                          : ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const Divider(height: 20),
                              itemBuilder: (_, index) {
                                final comment = items[index];
                                final author =
                                    comment.user?['full_name']?.toString() ?? 'User';
                                final isOwner =
                                    widget.currentUserId != null &&
                                    widget.currentUserId == comment.userId;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            author,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (isOwner)
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () async {
                                              final ok = await widget.onDeleteComment(comment.id);
                                              if (!ctx.mounted) return;
                                              if (ok) {
                                                setSheetState(() {
                                                  items = items
                                                      .where((it) => it.id != comment.id)
                                                      .toList();
                                                });
                                              }
                                            },
                                            icon: const Icon(Icons.delete_outline, size: 20),
                                          ),
                                      ],
                                    ),
                                    Text(comment.content),
                                    const SizedBox(height: 4),
                                    Text(
                                      _createdLabel(comment.createdAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.comments.length > 2
        ? widget.comments.take(2).toList()
        : widget.comments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.comments.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...preview.map((comment) {
            final author = comment.user?['full_name']?.toString() ?? 'User';
            final isOwner =
                widget.currentUserId != null && widget.currentUserId == comment.userId;

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          author,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isOwner)
                        GestureDetector(
                          onTap: () => widget.onDeleteComment(comment.id),
                          child: const Icon(Icons.delete_outline, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(comment.content),
                  const SizedBox(height: 4),
                  Text(
                    _createdLabel(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (widget.commentCount > 2)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _openAllCommentsModal,
                child: Text('View all comments (${widget.commentCount})'),
              ),
            ),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write a comment...',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}
