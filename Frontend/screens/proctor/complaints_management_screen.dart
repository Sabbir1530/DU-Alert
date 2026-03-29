import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint.dart';
import '../../config/constants.dart';
import '../../widgets/status_timeline.dart';

class ComplaintsManagementScreen extends StatefulWidget {
  const ComplaintsManagementScreen({super.key});

  @override
  State<ComplaintsManagementScreen> createState() =>
      _ComplaintsManagementScreenState();
}

class _ComplaintsManagementScreenState
    extends State<ComplaintsManagementScreen> {
  String? _filterCategory;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    context.read<ComplaintProvider>().fetchAll();
  }

  void _applyFilter() {
    context.read<ComplaintProvider>().fetchAll(
      category: _filterCategory,
      status: _filterStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ComplaintProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Complaints'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilter(context),
          ),
        ],
      ),
      body: cp.loading
          ? const Center(child: CircularProgressIndicator())
          : cp.allComplaints.isEmpty
          ? const Center(child: Text('No complaints'))
          : RefreshIndicator(
              onRefresh: () =>
                  cp.fetchAll(category: _filterCategory, status: _filterStatus),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: cp.allComplaints.length,
                itemBuilder: (_, i) =>
                    _MgmtComplaintCard(complaint: cp.allComplaints[i]),
              ),
            ),
    );
  }

  void _showFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _filterCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...AppConstants.complaintCategories.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (v) => _filterCategory = v,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _filterStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'Received', child: Text('Received')),
                DropdownMenuItem(
                  value: 'In Progress',
                  child: Text('In Progress'),
                ),
                DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
              ],
              onChanged: (v) => _filterStatus = v,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilter();
              },
              child: const Text('Apply Filter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MgmtComplaintCard extends StatelessWidget {
  final Complaint complaint;
  const _MgmtComplaintCard({required this.complaint});

  @override
  Widget build(BuildContext context) {
    final cp = context.read<ComplaintProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          complaint.category,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${complaint.status}'),
            if (complaint.creator != null)
              Text(
                'By: ${complaint.creator!['full_name'] ?? ''}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(complaint.description),
                const SizedBox(height: 12),
                const Text(
                  'Timeline',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                StatusTimeline(statusLog: complaint.statusLog),
                const SizedBox(height: 12),
                if (complaint.status != 'Resolved')
                  Row(
                    children: [
                      if (complaint.status == 'Received')
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () =>
                                cp.updateStatus(complaint.id, 'In Progress'),
                            child: const Text('Mark In Progress'),
                          ),
                        ),
                      if (complaint.status == 'Received')
                        const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () =>
                              cp.updateStatus(complaint.id, 'Resolved'),
                          child: const Text('Resolve'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
