import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.name.split(' ').map((p) => p[0]).take(2).join(),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(user.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.isManager ? Colors.blue.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      color: user.isManager ? Colors.blue.shade800 : Colors.green.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _Section(title: 'Account Details', children: [
            _InfoTile(icon: Icons.email_outlined, label: 'Email', value: user.email),
            if (user.phone != null) _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: user.phone!),
            _InfoTile(icon: Icons.access_time, label: 'Timezone', value: user.timezone ?? 'UTC'),
          ]),
          const SizedBox(height: 20),
          if (user.isManager)
            _Section(title: 'Manager', children: [
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('My Professionals'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ]),
          const SizedBox(height: 20),
          _Section(title: 'About', children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Schedulr'),
              subtitle: const Text('v1.0.0 — Multi-User Scheduling Module'),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade600, letterSpacing: 0.5)),
        ),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15)),
    );
  }
}
