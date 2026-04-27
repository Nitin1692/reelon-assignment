import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/schedule_provider.dart';
import '../../models/schedule_entry.dart';
import '../../utils/constants.dart';
import 'entry_detail_screen.dart';
import 'create_entry_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 720;
    return isTablet ? const _TabletCalendar() : const _MobileCalendar();
  }
}

class _MobileCalendar extends StatelessWidget {
  const _MobileCalendar();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => provider.setFocusedDay(DateTime.now()),
          ),
        ],
      ),
      body: Column(
        children: [
          _CalendarWidget(provider: provider),
          const Divider(height: 1),
          Expanded(child: _DayEntryList(provider: provider)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  void _openCreate(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEntryScreen()));
  }
}

class _TabletCalendar extends StatelessWidget {
  const _TabletCalendar();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEntryScreen())),
            icon: const Icon(Icons.add),
            label: const Text('Add Entry'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 360,
            child: Column(
              children: [
                _CalendarWidget(provider: provider),
                const Divider(height: 1),
                Expanded(child: _DayEntryList(provider: provider)),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _MonthOverview(provider: provider),
          ),
        ],
      ),
    );
  }
}

class _CalendarWidget extends StatelessWidget {
  final ScheduleProvider provider;
  const _CalendarWidget({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: provider.focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, provider.selectedDay),
      calendarFormat: CalendarFormat.month,
      availableCalendarFormats: const {CalendarFormat.month: 'Month'},
      eventLoader: (day) => provider.entriesForDay(day),
      onDaySelected: (selected, focused) {
        provider.setSelectedDay(selected);
        provider.setFocusedDay(focused);
      },
      onPageChanged: (focused) {
        provider.setFocusedDay(focused);
      },
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
        markersMaxCount: 3,
      ),
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}

class _DayEntryList extends StatelessWidget {
  final ScheduleProvider provider;
  const _DayEntryList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final day = provider.selectedDay ?? provider.focusedDay;
    final entries = provider.entriesForDay(day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(day),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              if (entries.isNotEmpty)
                Text('${entries.length} events', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
        if (entries.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_available, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('No events', style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: entries.length,
              itemBuilder: (ctx, i) => _EntryCard(entry: entries[i]),
            ),
          ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  final ScheduleEntry entry;
  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = Color(AppConstants.entryTypeColors[entry.entryType] ?? 0xFF9E9E9E);
    final fmt = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: entry.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppConstants.entryTypeLabels[entry.entryType] ?? entry.entryType,
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (entry.hasConflict) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.warning_amber, size: 14, color: Colors.orange),
                        ],
                        if (entry.isLinked) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.link, size: 14, color: Colors.blue),
                        ],
                        if (entry.requiresRsvp) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.how_to_reg, size: 14, color: Colors.purple),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.location != null)
                      Text(entry.location!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmt.format(entry.startsAt), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  Text(fmt.format(entry.endsAt), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthOverview extends StatelessWidget {
  final ScheduleProvider provider;
  const _MonthOverview({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final entries = provider.entries;
    final typeGroups = <String, int>{};
    for (final e in entries) {
      typeGroups[e.entryType] = (typeGroups[e.entryType] ?? 0) + 1;
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Month Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM yyyy').format(provider.focusedDay),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StatCard(label: 'Total', value: '${entries.length}', icon: Icons.event),
                const SizedBox(width: 12),
                _StatCard(label: 'Conflicts', value: '${entries.where((e) => e.hasConflict).length}', icon: Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 12),
                _StatCard(label: 'RSVP Needed', value: '${entries.where((e) => e.requiresRsvp).length}', icon: Icons.how_to_reg, color: Colors.purple),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('By Type', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final entry = typeGroups.entries.toList()[i];
              final color = Color(AppConstants.entryTypeColors[entry.key] ?? 0xFF9E9E9E);
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                title: Text(AppConstants.entryTypeLabels[entry.key] ?? entry.key),
                trailing: Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            },
            childCount: typeGroups.length,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  const _StatCard({required this.label, required this.value, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c)),
            Text(label, style: TextStyle(fontSize: 12, color: c.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }
}
