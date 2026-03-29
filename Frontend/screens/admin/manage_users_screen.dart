import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
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
    _deptCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Proctor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _deptCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nameCtrl.clear();
              _emailCtrl.clear();
              _deptCtrl.clear();
              _usernameCtrl.clear();
              _passwordCtrl.clear();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameCtrl.text.trim();
              final email = _emailCtrl.text.trim();
              final phone = _deptCtrl.text.trim();
              final username = _usernameCtrl.text.trim();
              final password = _passwordCtrl.text.trim();
              if (name.isEmpty ||
                  email.isEmpty ||
                  phone.isEmpty ||
                  username.isEmpty ||
                  password.isEmpty)
                return;
              Navigator.pop(context);
              await context.read<AdminProvider>().createProctor(
                fullName: name,
                email: email,
                phone: phone,
                username: username,
                password: password,
              );
              _nameCtrl.clear();
              _emailCtrl.clear();
              _deptCtrl.clear();
              _usernameCtrl.clear();
              _passwordCtrl.clear();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
