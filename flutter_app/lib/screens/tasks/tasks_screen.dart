import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../utils/constants.dart';
import 'create_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Overdue'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _TaskList(filter: 'active'),
          _TaskList(filter: 'overdue'),
          _TaskList(filter: 'completed'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskScreen())),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final String filter;
  const _TaskList({required this.filter});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    if (provider.loading) return const Center(child: CircularProgressIndicator());

    final tasks = switch (filter) {
      'overdue' => provider.overdueTasks,
      'completed' => provider.tasks.where((t) => t.isCompleted).toList(),
      _ => provider.activeTasks,
    };

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No ${filter == 'overdue' ? 'overdue ' : ''}tasks', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) => _TaskCard(task: tasks[i]),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TaskProvider>();
    final priorityColor = Color(AppConstants.priorityColors[task.priority] ?? 0xFF9E9E9E);
    final dateFmt = DateFormat('MMM d');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: task.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
            : IconButton(
                icon: Icon(Icons.radio_button_unchecked, color: priorityColor, size: 28),
                onPressed: () async {
                  await provider.completeTask(task.id);
                },
              ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.priority.toUpperCase(),
                    style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppConstants.taskTypeLabels[task.taskType] ?? task.taskType,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_today, size: 11, color: task.overdue ? Colors.red : Colors.grey.shade500),
                  const SizedBox(width: 2),
                  Text(
                    dateFmt.format(task.dueDate!),
                    style: TextStyle(fontSize: 11, color: task.overdue ? Colors.red : Colors.grey.shade500),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: task.isCompleted
            ? null
            : PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'complete', child: Text('Mark Complete')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                ],
                onSelected: (action) async {
                  if (action == 'complete') {
                    await provider.completeTask(task.id);
                  } else if (action == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CreateTaskScreen(existingTask: task)));
                  }
                },
              ),
      ),
    );
  }
}
