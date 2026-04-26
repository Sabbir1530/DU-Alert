import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint.dart';
import '../complaint/complaint_details_screen.dart';

class ComplaintTrackingScreen extends StatefulWidget {
  const ComplaintTrackingScreen({super.key});

  @override
  State<ComplaintTrackingScreen> createState() =>
      _ComplaintTrackingScreenState();
}

class _ComplaintTrackingScreenState extends State<ComplaintTrackingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ComplaintProvider>().fetchMy();
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ComplaintProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Complaints')),
      body: cp.loading
          ? const Center(child: CircularProgressIndicator())
          : cp.myComplaints.isEmpty
          ? const Center(child: Text('No complaints filed yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: cp.myComplaints.length,
              itemBuilder: (_, i) =>
                  _ComplaintCard(complaint: cp.myComplaints[i]),
            ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  const _ComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final subtitleDescription = complaint.description
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: _statusIcon(complaint.status),
        title: Text(
          complaint.title.isNotEmpty ? complaint.title : complaint.category,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Status: ${complaint.status}',
              style: TextStyle(
                color: _statusColor(complaint.status),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitleDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (complaint.media.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${complaint.media.length} attachment(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final provider = context.read<ComplaintProvider>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintDetailsScreen(
                complaintId: complaint.id,
                initialComplaint: complaint,
              ),
            ),
          ).then((_) => provider.fetchMy());
        },
      ),
    );
  }

  Icon _statusIcon(String status) {
    switch (status) {
      case 'Received':
        return const Icon(Icons.inbox, color: Colors.orange);
      case 'In Progress':
        return const Icon(Icons.pending, color: Colors.blue);
      case 'Resolved':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.info);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Received':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
