import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../utils/constants.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? existingTask;
  const CreateTaskScreen({super.key, this.existingTask});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _taskType = 'general';
  String _priority = 'medium';
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isEdit => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.existingTask!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description ?? '';
      _taskType = t.taskType;
      _priority = t.priority;
      _dueDate = t.dueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final params = {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'task_type': _taskType,
      'priority': _priority,
      'due_date': _dueDate?.toIso8601String().split('T').first,
    };

    try {
      final provider = context.read<TaskProvider>();
      if (_isEdit) {
        await provider.updateTask(widget.existingTask!.id, params);
      } else {
        await provider.createTask(params);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Task' : 'New Task'),
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
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Task Title', border: OutlineInputBorder()),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _taskType,
              decoration: const InputDecoration(labelText: 'Task Type', border: OutlineInputBorder()),
              items: AppConstants.taskTypeLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _taskType = v!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
              items: ['low', 'medium', 'high', 'urgent'].map((p) {
                final color = Color(AppConstants.priorityColors[p] ?? 0xFF9E9E9E);
                return DropdownMenuItem(
                  value: p,
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(p[0].toUpperCase() + p.substring(1)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due Date'),
              subtitle: Text(_dueDate != null ? DateFormat('EEEE, MMMM d, yyyy').format(_dueDate!) : 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            if (_dueDate != null)
              TextButton(
                onPressed: () => setState(() => _dueDate = null),
                child: const Text('Clear due date'),
              ),
          ],
        ),
      ),
    );
  }
}
