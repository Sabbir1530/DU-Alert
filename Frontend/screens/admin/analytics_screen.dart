import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../config/theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminProvider>().fetchAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();
    final data = ap.analytics;
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ap.loading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(child: Text('No data'))
          : RefreshIndicator(
              onRefresh: () => ap.fetchAnalytics(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryRow(data: data),
                  const SizedBox(height: 12),
                  _ComplaintLifecycleRow(data: data),
                  const SizedBox(height: 20),
                  _SectionTitle('Complaints by Category'),
                  _BarList(
                    items: _mapToList(data['byCategory']),
                    color: AppTheme.duGreen,
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('Complaints by Status'),
                  _BarList(
                    items: _mapToList(data['byStatus']),
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('Monthly Trend'),
                  _BarList(
                    items: _mapToList(data['monthly']),
                    color: Colors.purple,
                  ),
                ],
              ),
            ),
    );
  }

  List<MapEntry<String, int>> _mapToList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .map(
            (e) => MapEntry(
              e['label']?.toString() ?? '',
              int.tryParse('${e['count']}') ?? 0,
            ),
          )
          .toList();
    }
    if (raw is Map) {
      return raw.entries
          .map(
            (e) => MapEntry(e.key.toString(), int.tryParse('${e.value}') ?? 0),
          )
          .toList();
    }
    return [];
  }
}

class _SummaryRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SummaryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Users',
          value: '${data['totalUsers'] ?? 0}',
          icon: Icons.people,
          color: Colors.blue,
        ),
        _StatCard(
          label: 'Complaints',
          value: '${data['totalComplaints'] ?? 0}',
          icon: Icons.assignment,
          color: Colors.orange,
        ),
        _StatCard(
          label: 'Alerts',
          value: '${data['totalEmergencies'] ?? 0}',
          icon: Icons.emergency,
          color: Colors.red,
        ),
      ],
    );
  }
}

class _ComplaintLifecycleRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ComplaintLifecycleRow({required this.data});

  int _toInt(dynamic value) => int.tryParse('${value ?? 0}') ?? 0;

  @override
  Widget build(BuildContext context) {
    final summary = (data['complaintSummary'] as Map?) ?? const {};
    final resolved = _toInt(summary['resolved']);
    final inProgress = _toInt(summary['inProgress']);
    final received = _toInt(summary['received']);
    final total = _toInt(summary['total']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Complaint Summary'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniStatCard(
              label: 'Resolved',
              value: '$resolved',
              color: Colors.teal,
            ),
            _MiniStatCard(
              label: 'In Progress',
              value: '$inProgress',
              color: Colors.blue,
            ),
            _MiniStatCard(
              label: 'Received',
              value: '$received',
              color: Colors.amber.shade800,
            ),
            _MiniStatCard(
              label: 'Total',
              value: '$total',
              color: Colors.deepOrange,
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BarList extends StatelessWidget {
  final List<MapEntry<String, int>> items;
  final Color color;
  const _BarList({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('No data');
    final maxVal = items
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    return Column(
      children: items.map((e) {
        final fraction = maxVal > 0 ? e.value / maxVal : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  e.key,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                  minHeight: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${e.value}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
