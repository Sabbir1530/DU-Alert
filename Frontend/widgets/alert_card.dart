import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../config/theme.dart';
import '../models/public_alert.dart';
import 'comment_section.dart';
import 'media_viewer.dart';
import 'reaction_bar.dart';

typedef ReactCallback = Future<bool> Function(String type);
typedef RemoveReactionCallback = Future<bool> Function();
typedef AddCommentToAlertCallback = Future<bool> Function(String content);
typedef DeleteCommentFromAlertCallback =
    Future<bool> Function(String commentId);
typedef LoadAllCommentsCallback = Future<List<PublicAlertComment>> Function();

class AlertCard extends StatelessWidget {
  final PublicAlert alert;
  final String? currentUserId;
  final ReactCallback onReact;
  final RemoveReactionCallback onRemoveReaction;
  final AddCommentToAlertCallback onAddComment;
  final DeleteCommentFromAlertCallback onDeleteComment;
  final LoadAllCommentsCallback onLoadComments;

  const AlertCard({
    super.key,
    required this.alert,
    required this.currentUserId,
    required this.onReact,
    required this.onRemoveReaction,
    required this.onAddComment,
    required this.onDeleteComment,
    required this.onLoadComments,
  });

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

  Future<void> _handleReaction(String type) async {
    if (alert.myReaction == type) {
      await onRemoveReaction();
      return;
    }
    await onReact(type);
  }

  String _profileUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.isEmpty) return value;
    final base = AppConstants.serverOrigin.endsWith('/')
        ? AppConstants.serverOrigin.substring(
            0,
            AppConstants.serverOrigin.length - 1,
          )
        : AppConstants.serverOrigin;
    final path = value.startsWith('/') ? value : '/$value';
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = alert.anonymous || alert.creator == null
        ? 'Anonymous'
        : (alert.creator!['full_name']?.toString() ?? 'Unknown User');
    final department = alert.creator?['department']?.toString() ?? '';
    final profileImageUrl = _profileUrl(
      alert.creator?['profile_image_url']?.toString() ?? '',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isNotEmpty
                      ? null
                      : Text(
                          displayName.isNotEmpty
                              ? displayName.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (department.isNotEmpty)
                        Text(
                          department,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        _timeAgo(alert.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    alert.category,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _ExpandableDescription(
              text: alert.description,
              style: const TextStyle(fontSize: 15, height: 1.4),
              trimLines: 3,
            ),
            MediaViewer(media: alert.media),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${alert.reactionCount} reactions',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${alert.commentCount} comments',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ReactionBar(
              myReaction: alert.myReaction,
              summary: alert.reactionSummary,
              onReact: _handleReaction,
            ),
            const SizedBox(height: 10),
            CommentSection(
              alertId: alert.id,
              comments: alert.comments,
              commentCount: alert.commentCount,
              currentUserId: currentUserId,
              onAddComment: onAddComment,
              onDeleteComment: onDeleteComment,
              onLoadComments: onLoadComments,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableDescription extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int trimLines;

  const _ExpandableDescription({
    required this.text,
    this.style,
    this.trimLines = 3,
  });

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _isOverflowing = false;

  @override
  Widget build(BuildContext context) {
    if (widget.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(text: widget.text, style: widget.style);
        final textPainter = TextPainter(
          text: textSpan,
          maxLines: widget.trimLines,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        _isOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: Text(
                widget.text,
                style: widget.style,
                maxLines: _expanded ? null : widget.trimLines,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.fade,
              ),
            ),
            if (_isOverflowing)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded ? 'See Less' : 'See More',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
