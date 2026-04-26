import 'package:flutter/material.dart';

class StatusTimeline extends StatelessWidget {
  final List<dynamic> statusLog;
  const StatusTimeline({super.key, required this.statusLog});

  @override
  Widget build(BuildContext context) {
    if (statusLog.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No status updates yet'),
      );
    }
    return Column(
      children: List.generate(statusLog.length, (i) {
        final entry = statusLog[i];
        final status = entry['status'] ?? '';
        final note = entry['note'] ?? '';
        final date = entry['createdAt'] ?? entry['created_at'] ?? '';
        final isLast = i == statusLog.length - 1;
        return _TimelineItem(
          status: status,
          note: note,
          date: date,
          isLast: isLast,
        );
      }),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String status;
  final String note;
  final String date;
  final bool isLast;

  const _TimelineItem({
    required this.status,
    required this.note,
    required this.date,
    required this.isLast,
  });

  Color get _color {
    switch (status) {
      case 'Received':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = date.contains('T') ? date.split('T').first : date;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: _color.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _color,
                    ),
                  ),
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(note, style: const TextStyle(fontSize: 13)),
                    ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
