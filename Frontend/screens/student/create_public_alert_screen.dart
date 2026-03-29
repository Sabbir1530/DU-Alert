import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/public_alert_provider.dart';
import '../../config/constants.dart';

class CreatePublicAlertScreen extends StatefulWidget {
  const CreatePublicAlertScreen({super.key});

  @override
  State<CreatePublicAlertScreen> createState() =>
      _CreatePublicAlertScreenState();
}

class _CreatePublicAlertScreenState extends State<CreatePublicAlertScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  String? _category;
  bool _anonymous = false;
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
    final pa = context.read<PublicAlertProvider>();
    final ok = await pa.create(
      category: _category!,
      description: _descCtrl.text.trim(),
      anonymous: _anonymous,
      mediaFiles: _mediaFiles.isEmpty ? null : _mediaFiles,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert submitted for approval')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(pa.error ?? 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pa = context.watch<PublicAlertProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Create Public Alert')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: AppConstants.alertCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Post Anonymously'),
                subtitle: const Text('Your identity will be hidden'),
                value: _anonymous,
                onChanged: (v) => setState(() => _anonymous = v),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.photo_library),
                label: Text('Attach Media (${_mediaFiles.length} selected)'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: pa.loading ? null : _submit,
                child: pa.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Alert'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Your alert will be reviewed by admins before publishing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
