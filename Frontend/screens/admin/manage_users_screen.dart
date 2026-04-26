import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/user.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _createProctorFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminProvider>().fetchUsers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _resetCreateProctorForm() {
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _usernameCtrl.clear();
    _passwordCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProctorDialog(context),
        label: const Text('Add Proctor'),
        icon: const Icon(Icons.person_add),
      ),
      body: ap.loading
          ? const Center(child: CircularProgressIndicator())
          : ap.users.isEmpty
          ? const Center(child: Text('No users'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: ap.users.length,
              itemBuilder: (_, i) {
                final user = ap.users[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _showUserDetails(user),
                    leading: CircleAvatar(
                      backgroundColor: user.role == 'admin'
                          ? Colors.red
                          : user.role == 'proctor'
                          ? Colors.blue
                          : Colors.green,
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user.fullName),
                    subtitle: Text('${user.role}  •  ${user.department ?? ""}'),
                    trailing: user.role != 'admin'
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _confirmDelete(user.id, user.fullName),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${user.fullName}'),
              const SizedBox(height: 6),
              Text('Role: ${user.role}'),
              const SizedBox(height: 6),
              Text('Username: ${user.username}'),
              const SizedBox(height: 6),
              Text('Email: ${user.universityEmail}'),
              const SizedBox(height: 6),
              Text('Phone: ${user.phone}'),
              const SizedBox(height: 6),
              Text('Department: ${user.department ?? 'N/A'}'),
              const SizedBox(height: 6),
              Text('Registration No: ${user.registrationNumber ?? 'N/A'}'),
              const SizedBox(height: 6),
              Text('User ID: ${user.id}'),
              if (user.createdAt.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Created At: ${user.createdAt}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AdminProvider>().deleteUser(id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCreateProctorDialog(BuildContext context) {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Proctor'),
        content: Form(
          key: _createProctorFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Full name is required'
                      : null,
                ),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'University Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Email is required';
                    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                    if (!regex.hasMatch(value)) return 'Enter a valid email';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Phone is required'
                      : null,
                ),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Username is required'
                      : null,
                ),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Password is required';
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _resetCreateProctorForm();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final isValid =
                  _createProctorFormKey.currentState?.validate() ?? false;
              if (!isValid) return;

              final name = _nameCtrl.text.trim();
              final email = _emailCtrl.text.trim();
              final phone = _phoneCtrl.text.trim();
              final username = _usernameCtrl.text.trim();
              final password = _passwordCtrl.text.trim();

              Navigator.pop(dialogContext);
              final provider = parentContext.read<AdminProvider>();
              final messenger = ScaffoldMessenger.of(parentContext);

              final ok = await provider.createProctor(
                fullName: name,
                email: email,
                phone: phone,
                username: username,
                password: password,
              );

              if (!mounted) return;

              if (ok) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Proctor account created successfully.'),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.error ?? 'Failed to create proctor account.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }

              _resetCreateProctorForm();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
