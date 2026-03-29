import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/complaint_provider.dart';
import '../../config/constants.dart';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  String? _category;
  final List<Map<String, String>> _complainants = [{}];
  final List<Map<String, String>> _accused = [];
  final List<File> _mediaFiles = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final files = await _picker.pickMultiImage();
    for (final xf in files) {
      _mediaFiles.add(File(xf.path));
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    final validComplainants = _complainants
        .where((c) => c['name'] != null && c['name']!.isNotEmpty)
        .toList();

    final cp = context.read<ComplaintProvider>();
    final ok = await cp.createComplaint(
      category: _category!,
      description: _descCtrl.text.trim(),
      complainants: validComplainants.isEmpty ? null : validComplainants,
      accused: _accused.isEmpty ? null : _accused,
      mediaFiles: _mediaFiles.isEmpty ? null : _mediaFiles,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint filed successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(cp.error ?? 'Failed to file complaint')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<ComplaintProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: AppConstants.complaintCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),

              // Complainants
              const Text(
                'Complainants',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._complainants.asMap().entries.map((e) {
                final i = e.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Name ${i + 1}',
                          ),
                          onChanged: (v) => _complainants[i]['name'] = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Reg No (opt)',
                          ),
                          onChanged: (v) =>
                              _complainants[i]['registration_number'] = v,
                        ),
                      ),
                      if (i > 0)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              setState(() => _complainants.removeAt(i)),
                        ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _complainants.add({})),
                icon: const Icon(Icons.add),
                label: const Text('Add Complainant'),
              ),
              const SizedBox(height: 16),

              // Accused (optional)
              const Text(
                'Accused (Optional)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._accused.asMap().entries.map((e) {
                final i = e.key;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Name'),
                          onChanged: (v) => _accused[i]['name'] = v,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Department',
                          ),
                          onChanged: (v) => _accused[i]['department'] = v,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          onChanged: (v) => _accused[i]['description'] = v,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _accused.removeAt(i)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => setState(() => _accused.add({})),
                icon: const Icon(Icons.add),
                label: const Text('Add Accused'),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Detailed Description',
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Provide a description' : null,
              ),
              const SizedBox(height: 16),

              // Media
              OutlinedButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.attach_file),
                label: Text('Attach Media (${_mediaFiles.length} selected)'),
              ),
              if (_mediaFiles.isNotEmpty)
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mediaFiles.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.all(4),
                      child: Stack(
                        children: [
                          Image.file(
                            _mediaFiles[i],
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _mediaFiles.removeAt(i)),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: cp.loading ? null : _submit,
                child: cp.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
