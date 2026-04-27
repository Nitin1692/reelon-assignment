import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/schedule_entry.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/constants.dart';

class CreateEntryScreen extends StatefulWidget {
  final ScheduleEntry? existingEntry;
  const CreateEntryScreen({super.key, this.existingEntry});

  @override
  State<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String _entryType = 'available';
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _allDay = false;
  bool _requiresRsvp = false;
  bool _saving = false;
  bool _conflictChecked = false;
  bool _hasConflicts = false;
  List<dynamic> _conflicts = [];

  bool get _isEdit => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existingEntry!;
      _titleCtrl.text = e.title ?? '';
      _notesCtrl.text = e.notes ?? '';
      _locationCtrl.text = e.location ?? '';
      _entryType = e.entryType;
      _startDate = e.startsAt;
      _startTime = TimeOfDay.fromDateTime(e.startsAt);
      _endDate = e.endsAt;
      _endTime = TimeOfDay.fromDateTime(e.endsAt);
      _allDay = e.allDay;
      _requiresRsvp = e.requiresRsvp;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  DateTime get _startsAt => DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
  DateTime get _endsAt => DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);

  Future<void> _checkConflicts() async {
    setState(() { _conflictChecked = false; _hasConflicts = false; _conflicts = []; });
    try {
      final result = await context.read<ScheduleProvider>().checkConflicts(
        startsAt: _startsAt,
        endsAt: _endsAt,
        excludeId: _isEdit ? widget.existingEntry!.id : null,
      );
      setState(() {
        _conflictChecked = true;
        _hasConflicts = result['has_conflicts'] ?? false;
        _conflicts = result['conflicts'] ?? [];
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endsAt.isBefore(_startsAt) || _endsAt.isAtSameMomentAs(_startsAt)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _saving = true);

    final params = {
      'entry_type': _entryType,
      'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      'location': _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      'starts_at': _startsAt.toUtc().toIso8601String(),
      'ends_at': _endsAt.toUtc().toIso8601String(),
      'all_day': _allDay,
      'requires_rsvp': _requiresRsvp,
    };

    try {
      final sp = context.read<ScheduleProvider>();
      if (_isEdit) {
        await sp.updateEntry(widget.existingEntry!.id, params);
      } else {
        await sp.createEntry(params);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Entry' : 'New Schedule Entry'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Entry type
            DropdownButtonFormField<String>(
              value: _entryType,
              decoration: const InputDecoration(labelText: 'Entry Type', border: OutlineInputBorder()),
              items: AppConstants.entryTypeLabels.entries.map((e) {
                final color = Color(AppConstants.entryTypeColors[e.key] ?? 0xFF9E9E9E);
                return DropdownMenuItem(
                  value: e.key,
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(e.value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _entryType = v!),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // Date/time
            _SectionLabel('Date & Time'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('All day'),
              value: _allDay,
              onChanged: (v) => setState(() => _allDay = v),
            ),

            Row(children: [
              Expanded(child: _DateTimeField(label: 'Start Date', value: dateFmt.format(_startDate), onTap: () => _pickDate(true))),
              const SizedBox(width: 12),
              if (!_allDay) Expanded(child: _DateTimeField(label: 'Start Time', value: _startTime.format(context), onTap: () => _pickTime(true))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _DateTimeField(label: 'End Date', value: dateFmt.format(_endDate), onTap: () => _pickDate(false))),
              const SizedBox(width: 12),
              if (!_allDay) Expanded(child: _DateTimeField(label: 'End Time', value: _endTime.format(context), onTap: () => _pickTime(false))),
            ]),

            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _checkConflicts,
              icon: const Icon(Icons.warning_amber, size: 16),
              label: const Text('Check for Conflicts'),
            ),
            if (_conflictChecked) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hasConflicts ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _hasConflicts ? Colors.orange.shade300 : Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(_hasConflicts ? Icons.warning_amber : Icons.check_circle,
                        color: _hasConflicts ? Colors.orange : Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _hasConflicts ? '${_conflicts.length} conflict(s) found' : 'No conflicts found',
                      style: TextStyle(color: _hasConflicts ? Colors.orange.shade800 : Colors.green.shade800),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            _SectionLabel('Details'),

            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(labelText: 'Location (optional)', prefixIcon: Icon(Icons.location_on_outlined), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            _SectionLabel('RSVP'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Require RSVP'),
              subtitle: const Text('Participants will be asked to confirm'),
              value: _requiresRsvp,
              onChanged: (v) => setState(() => _requiresRsvp = v),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.grey.shade600, letterSpacing: 0.5)),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateTimeField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(value, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
