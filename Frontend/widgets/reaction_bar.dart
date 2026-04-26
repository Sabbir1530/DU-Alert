import 'package:flutter/material.dart';
import '../config/theme.dart';

class ReactionBar extends StatelessWidget {
  final String? myReaction;
  final Map<String, int> summary;
  final ValueChanged<String> onReact;

  const ReactionBar({
    super.key,
    required this.myReaction,
    required this.summary,
    required this.onReact,
  });

  Widget _reactionChip({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final selected = myReaction == type;
    final count = summary[type] ?? 0;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onReact(type),
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? AppTheme.primary : AppTheme.textSecondary,
      ),
      label: Text('$label ($count)'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _reactionChip(
          type: 'like',
          label: 'Like',
          icon: Icons.thumb_up_alt_outlined,
        ),
        _reactionChip(
          type: 'important',
          label: 'Important',
          icon: Icons.priority_high,
        ),
      ],
    );
  }
}
