import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint.dart';
import '../../config/constants.dart';
import '../complaint/complaint_details_screen.dart';
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
              initialValue: _filterCategory,
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
              initialValue: _filterStatus,
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

class _MgmtComplaintCard extends StatefulWidget {
  final Complaint complaint;
  const _MgmtComplaintCard({required this.complaint});

  @override
  State<_MgmtComplaintCard> createState() => _MgmtComplaintCardState();
}

class _MgmtComplaintCardState extends State<_MgmtComplaintCard> {
  late final TextEditingController _judgementCtrl;
  bool _updating = false;

  Complaint get complaint => widget.complaint;

  @override
  void initState() {
    super.initState();
    _judgementCtrl = TextEditingController(
      text: complaint.judgementDetails ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _MgmtComplaintCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.complaint.id != complaint.id ||
        oldWidget.complaint.judgementDetails != complaint.judgementDetails) {
      _judgementCtrl.text = complaint.judgementDetails ?? '';
    }
  }

  @override
  void dispose() {
    _judgementCtrl.dispose();
    super.dispose();
  }

  String _statusLabel(String status) {
    if (status == 'Resolved') return 'Solved';
    return status;
  }

  String _createdDate() {
    if (complaint.createdAt.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(complaint.createdAt);
    if (dt == null) return complaint.createdAt;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  String _mediaUrl(String fileUrl) {
    if (fileUrl.startsWith('http://') || fileUrl.startsWith('https://')) {
      return fileUrl;
    }
    final base = AppConstants.serverOrigin.endsWith('/')
        ? AppConstants.serverOrigin.substring(
            0,
            AppConstants.serverOrigin.length - 1,
          )
        : AppConstants.serverOrigin;
    final path = fileUrl.startsWith('/') ? fileUrl : '/$fileUrl';
    return '$base$path';
  }

  Future<void> _openComplaintDetails() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintDetailsScreen(
          complaintId: complaint.id,
          initialComplaint: complaint,
        ),
      ),
    );

    if (!mounted) return;
    await context.read<ComplaintProvider>().fetchAll();
  }

  Future<void> _openAttachment(String fileUrl) async {
    final uri = Uri.tryParse(_mediaUrl(fileUrl));
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment')),
      );
    }
  }

  Future<void> _printPdf() async {
    final doc = pw.Document();

    final victims = complaint.complainants
        .map((v) {
          final name = (v['name'] ?? '').toString();
          final reg = (v['registration_number'] ?? '').toString();
          return reg.isNotEmpty ? '$name ($reg)' : name;
        })
        .where((v) => v.trim().isNotEmpty)
        .toList();

    final accused = complaint.accusedPersons
        .map((a) {
          final name = (a['name'] ?? '').toString();
          final dep = (a['department'] ?? '').toString();
          final desc = (a['description'] ?? '').toString();
          final depPart = dep.isNotEmpty ? 'Department: $dep' : null;
          final descPart = desc.isNotEmpty ? 'Description: $desc' : null;
          return [
            name,
            depPart,
            descPart,
          ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' | ');
        })
        .where((a) => a.trim().isNotEmpty)
        .toList();

    final attachments = complaint.media
        .map((m) => (m['file_url'] ?? '').toString())
        .where((m) => m.isNotEmpty)
        .map(_mediaUrl)
        .toList();

    doc.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Text(
            'DU Alert Complaint Report',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Title: ${complaint.title.isNotEmpty ? complaint.title : complaint.category}',
          ),
          pw.Text('Category: ${complaint.category}'),
          pw.Text('Status: ${_statusLabel(complaint.status)}'),
          pw.Text('Created At: ${_createdDate()}'),
          pw.SizedBox(height: 10),
          pw.Text(
            'Description',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(complaint.description),
          pw.SizedBox(height: 12),
          pw.Text(
            'Victims',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (victims.isEmpty)
            pw.Text('None provided')
          else
            ...victims.map((v) => pw.Text(v)),
          pw.SizedBox(height: 12),
          pw.Text(
            'Accused',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (accused.isEmpty)
            pw.Text('None provided')
          else
            ...accused.map((a) => pw.Text(a)),
          pw.SizedBox(height: 12),
          pw.Text(
            'Attachments',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (attachments.isEmpty)
            pw.Text('No attachments')
          else
            ...attachments.map((a) => pw.Text(a)),
          if ((complaint.judgementDetails ?? '').trim().isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'Judgement Details',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(complaint.judgementDetails!.trim()),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }

  Future<void> _changeStatus(String status) async {
    setState(() => _updating = true);
    final cp = context.read<ComplaintProvider>();

    final judgement = status == 'Resolved' ? _judgementCtrl.text.trim() : '';

    final ok = await cp.updateStatus(
      complaint.id,
      status,
      judgementDetails: judgement,
    );

    if (!mounted) return;
    setState(() => _updating = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cp.error ?? 'Failed to update status')),
      );
    }
  }

  Future<void> _saveJudgement() async {
    if (_judgementCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a short judgement first')),
      );
      return;
    }

    setState(() => _updating = true);
    final cp = context.read<ComplaintProvider>();
    final ok = await cp.updateStatus(
      complaint.id,
      complaint.status,
      judgementDetails: _judgementCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _updating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Judgement saved' : (cp.error ?? 'Failed to save judgement'),
        ),
      ),
    );
  }

  Widget _peopleList(
    String title,
    List<Map<String, dynamic>> people, {
    required String Function(Map<String, dynamic>) formatter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        if (people.isEmpty)
          const Text('None provided', style: TextStyle(color: Colors.grey))
        else
          ...people.map(
            (person) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${formatter(person)}'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statuses = const ['Received', 'In Progress', 'Resolved'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          complaint.title.isNotEmpty ? complaint.title : complaint.category,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_statusLabel(complaint.status)}'),
            if (complaint.creator != null)
              Text(
                'By: ${complaint.creator!['full_name'] ?? ''}',
                style: const TextStyle(fontSize: 12),
              ),
            Text(
              'Created: ${_createdDate()}',
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
                Text(
                  'Category: ${complaint.category}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(complaint.description),
                if ((complaint.judgementDetails ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Judgement Details',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(complaint.judgementDetails!.trim()),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openComplaintDetails,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Details Page'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _printPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Print PDF'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _peopleList(
                  'Victims',
                  complaint.complainants,
                  formatter: (person) {
                    final name = (person['name'] ?? '').toString().trim();
                    final reg = (person['registration_number'] ?? '')
                        .toString()
                        .trim();
                    if (reg.isEmpty) return name;
                    return '$name ($reg)';
                  },
                ),
                const SizedBox(height: 10),
                _peopleList(
                  'Accused',
                  complaint.accusedPersons,
                  formatter: (person) {
                    final name = (person['name'] ?? '').toString().trim();
                    final dep = (person['department'] ?? '').toString().trim();
                    final desc = (person['description'] ?? '')
                        .toString()
                        .trim();
                    final parts = [
                      if (name.isNotEmpty) name,
                      if (dep.isNotEmpty) 'Department: $dep',
                      if (desc.isNotEmpty) desc,
                    ];
                    return parts.join(' | ');
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Attachments',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (complaint.media.isEmpty)
                  const Text(
                    'No attachments',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  ...complaint.media.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final media = entry.value;
                    final fileUrl = (media['file_url'] ?? '').toString();
                    final absolute = _mediaUrl(fileUrl);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.attach_file),
                      title: Text('Attachment $idx'),
                      subtitle: Text(
                        absolute,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: TextButton(
                        onPressed: () => _openAttachment(fileUrl),
                        child: const Text('Open'),
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                const Text(
                  'Timeline',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                StatusTimeline(statusLog: complaint.statusLog),
                const SizedBox(height: 12),
                const Text(
                  'Update Status',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statuses.map((s) {
                    final selected = complaint.status == s;
                    return ChoiceChip(
                      label: Text(_statusLabel(s)),
                      selected: selected,
                      onSelected: _updating || selected
                          ? null
                          : (_) => _changeStatus(s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _judgementCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Judgement Details (for solved complaints)',
                    hintText: 'Write short judgement notes here...',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _updating ? null : _saveJudgement,
                    icon: const Icon(Icons.gavel),
                    label: const Text('Save Judgement'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
