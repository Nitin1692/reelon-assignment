import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/schedule_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/schedule_provider.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import 'create_entry_screen.dart';

class EntryDetailScreen extends StatefulWidget {
  final int entryId;
  const EntryDetailScreen({super.key, required this.entryId});

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  ScheduleEntry? _entry;
  bool _loading = true;
  String? _error;
  String? _rsvpResponse;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entry = await ApiService().getScheduleEntry(widget.entryId);
      setState(() { _entry = entry; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _rsvp(String response) async {
    try {
      await ApiService().rsvp(widget.entryId, response);
      setState(() => _rsvpResponse = response);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('RSVP updated: $response'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Entry'),
        content: const Text('Are you sure you want to cancel this schedule entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<ScheduleProvider>().cancelEntry(widget.entryId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!)));

    final entry = _entry!;
    final color = Color(AppConstants.entryTypeColors[entry.entryType] ?? 0xFF9E9E9E);
    final fmt = DateFormat('EEE, MMM d · HH:mm');
    final currentUser = context.read<AuthProvider>().user!;
    final canEdit = currentUser.id == entry.userId || currentUser.isManager;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.entryTypeLabels[entry.entryType] ?? entry.entryType),
        actions: [
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateEntryScreen(existingEntry: entry)),
              ).then((_) => _load()),
            ),
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: _cancel,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(AppConstants.entryTypeLabels[entry.entryType] ?? entry.entryType,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Title
            if (entry.title != null && entry.title!.isNotEmpty)
              Text(entry.title!, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),

            const SizedBox(height: 16),

            // Time
            _InfoRow(icon: Icons.schedule, label: 'Start', value: fmt.format(entry.startsAt)),
            const SizedBox(height: 8),
            _InfoRow(icon: Icons.schedule_outlined, label: 'End', value: fmt.format(entry.endsAt)),

            if (entry.location != null) ...[
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.location_on_outlined, label: 'Location', value: entry.location!),
            ],

            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.notes, label: 'Notes', value: entry.notes!),
            ],

            if (entry.createdBy != null) ...[
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.person_outline, label: 'Created by', value: entry.createdBy!['name']),
            ],

            // Conflict warning
            if (entry.hasConflict) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('This entry conflicts with other schedule entries.', style: TextStyle(color: Colors.orange))),
                  ],
                ),
              ),
            ],

            // RSVP section
            if (entry.requiresRsvp) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text('RSVP', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (entry.rsvpSummary != null)
                _RsvpSummary(summary: entry.rsvpSummary!),
              const SizedBox(height: 12),
              Row(
                children: [
                  _RsvpButton(label: 'Yes', icon: Icons.check_circle, color: Colors.green, selected: _rsvpResponse == 'yes', onTap: () => _rsvp('yes')),
                  const SizedBox(width: 8),
                  _RsvpButton(label: 'No', icon: Icons.cancel, color: Colors.red, selected: _rsvpResponse == 'no', onTap: () => _rsvp('no')),
                  const SizedBox(width: 8),
                  _RsvpButton(label: 'Maybe', icon: Icons.help_outline, color: Colors.orange, selected: _rsvpResponse == 'maybe', onTap: () => _rsvp('maybe')),
                ],
              ),
            ],

            // Audit trail
            if (entry.updatedBy != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              Text('Last updated by ${entry.updatedBy!['name']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],

            // Linked source
            if (entry.isLinked) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.link, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text('Linked to ${entry.sourceType?.replaceAll('_', ' ')}', style: const TextStyle(color: Colors.blue, fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RsvpSummary extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _RsvpSummary({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip('${summary['yes']}', 'Yes', Colors.green),
        const SizedBox(width: 8),
        _chip('${summary['no']}', 'No', Colors.red),
        const SizedBox(width: 8),
        _chip('${summary['maybe']}', 'Maybe', Colors.orange),
        const SizedBox(width: 8),
        _chip('${summary['pending']}', 'Pending', Colors.grey),
      ],
    );
  }

  Widget _chip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count $label', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}

class _RsvpButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RsvpButton({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: selected ? Colors.white : color),
        label: Text(label, style: TextStyle(color: selected ? Colors.white : color)),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? color : null,
          side: BorderSide(color: color),
        ),
      ),
    );
  }
}
