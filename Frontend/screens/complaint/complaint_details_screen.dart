import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/constants.dart';
import '../../models/complaint.dart';
import '../../providers/complaint_provider.dart';
import '../../widgets/status_timeline.dart';

class ComplaintDetailsScreen extends StatefulWidget {
  final String complaintId;
  final Complaint? initialComplaint;

  const ComplaintDetailsScreen({
    super.key,
    required this.complaintId,
    this.initialComplaint,
  });

  @override
  State<ComplaintDetailsScreen> createState() => _ComplaintDetailsScreenState();
}

class _ComplaintDetailsScreenState extends State<ComplaintDetailsScreen> {
  String? _displayedSummary;
  bool _summaryLoading = false;
  String? _summaryError;
  bool _summaryExpanded = true;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ComplaintProvider>();
    Future.microtask(() => provider.fetchById(widget.complaintId));
  }

  Complaint? _currentComplaint(ComplaintProvider provider) {
    final selected = provider.selected;
    if (selected != null && selected.id == widget.complaintId) {
      return selected;
    }

    if (widget.initialComplaint != null &&
        widget.initialComplaint!.id == widget.complaintId) {
      return widget.initialComplaint;
    }

    return null;
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }

  String _statusLabel(String status) {
    return status;
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Received':
        return Icons.inbox;
      case 'In Progress':
        return Icons.pending_actions;
      case 'Resolved':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Future<void> _generateSummary(String complaintId) async {
    if (_summaryLoading) return;

    setState(() {
      _summaryLoading = true;
      _summaryError = null;
    });

    try {
      final provider = context.read<ComplaintProvider>();
      final response = await provider.generateSummary(complaintId);
      final summary = (response['summary'] ?? '').toString().trim();

      if (summary.isEmpty) {
        throw Exception('AI summary service unavailable. Please try again.');
      }

      if (mounted) {
        setState(() {
          _displayedSummary = summary;
          _summaryExpanded = true;
          _summaryLoading = false;
          _summaryError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        var errorMsg = e.toString().trim();
        if (errorMsg.startsWith('Exception: ')) {
          errorMsg = errorMsg.substring('Exception: '.length).trim();
        }
        if (errorMsg.isEmpty || errorMsg == 'Exception') {
          errorMsg = 'AI summary service unavailable. Please try again.';
        }

        setState(() {
          _summaryLoading = false;
          _summaryError = errorMsg;
        });
      }
    }
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

  bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.heif');
  }

  Future<void> _openMedia(String fileUrl) async {
    final uri = Uri.tryParse(_mediaUrl(fileUrl));
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open attachment')),
      );
    }
  }

  Widget _peopleSection(
    String title,
    List<Map<String, dynamic>> people, {
    required String Function(Map<String, dynamic>) formatter,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (people.isEmpty)
              const Text('None provided', style: TextStyle(color: Colors.grey))
            else
              ...people.map(
                (person) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('- ${formatter(person)}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentItem(Map<String, dynamic> media) {
    final fileUrl = media['file_url']?.toString() ?? '';
    final absoluteUrl = _mediaUrl(fileUrl);

    if (_isImagePath(fileUrl)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => _openMedia(fileUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              absoluteUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 180,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.insert_drive_file_outlined),
      title: Text(fileUrl.split('/').last),
      subtitle: Text(absoluteUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: TextButton(
        onPressed: () => _openMedia(fileUrl),
        child: const Text('Open'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComplaintProvider>();
    final complaint = _currentComplaint(provider);

    if (complaint == null && provider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (complaint == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complaint Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(provider.error ?? 'Could not load complaint details'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => provider.fetchById(widget.complaintId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final shownSummary = (_displayedSummary ?? complaint.summary)?.trim();
    final hasSummary = shownSummary != null && shownSummary.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchById(widget.complaintId),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.title.isNotEmpty
                          ? complaint.title
                          : complaint.category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('Category: ${complaint.category}')),
                        Chip(
                          avatar: Icon(
                            _statusIcon(complaint.status),
                            color: _statusColor(complaint.status),
                            size: 18,
                          ),
                          label: Text(_statusLabel(complaint.status)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Created: ${_formatDate(complaint.createdAt)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(complaint.description),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _generateSummary(complaint.id),
                        icon: _summaryLoading
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              )
                            : const Icon(Icons.summarize_outlined),
                        label: Text(
                          _summaryLoading
                              ? 'Generating AI Summary...'
                              : 'Generate Summary',
                        ),
                      ),
                    ),
                    if (hasSummary) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _summaryExpanded = !_summaryExpanded;
                          });
                        },
                        child: Row(
                          children: [
                            Icon(
                              _summaryExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AI Generated Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_summaryExpanded) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            shownSummary,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ],
                    if (_summaryError != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _summaryError!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Attachments',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (complaint.media.isEmpty)
                      const Text(
                        'No attachments provided',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...complaint.media.map(_attachmentItem),
                  ],
                ),
              ),
            ),
            if ((complaint.judgementDetails ?? '').trim().isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Judgement Details',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(complaint.judgementDetails!.trim()),
                    ],
                  ),
                ),
              ),
            _peopleSection(
              'Complainants',
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
            _peopleSection(
              'Accused',
              complaint.accusedPersons,
              formatter: (person) {
                final name = (person['name'] ?? '').toString().trim();
                final dep = (person['department'] ?? '').toString().trim();
                final desc = (person['description'] ?? '').toString().trim();
                final parts = [
                  if (name.isNotEmpty) name,
                  if (dep.isNotEmpty) 'Department: $dep',
                  if (desc.isNotEmpty) desc,
                ];
                return parts.isEmpty ? 'N/A' : parts.join(' | ');
              },
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Timeline',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    StatusTimeline(statusLog: complaint.statusLog),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
