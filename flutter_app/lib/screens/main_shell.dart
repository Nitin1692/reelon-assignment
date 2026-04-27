import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/task_provider.dart';
import '../providers/notification_provider.dart';
import 'calendar/calendar_screen.dart';
import 'tasks/tasks_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  Future<void> _loadInitialData() async {
    final schedule = context.read<ScheduleProvider>();
    final tasks = context.read<TaskProvider>();
    final notifications = context.read<NotificationProvider>();
    await Future.wait([
      schedule.loadMonthEntries(DateTime.now()),
      tasks.loadTasks(),
      notifications.load(),
    ]);
  }

  static const _screens = [
    CalendarScreen(),
    TasksScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;
    final isTablet = MediaQuery.of(context).size.width >= 720;

    if (isTablet) {
      return _TabletLayout(currentIndex: _currentIndex, onTabChanged: (i) => setState(() => _currentIndex = i), unread: unread);
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Calendar'),
          const NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(
            icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_outlined)),
            selectedIcon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications)),
            label: 'Notifications',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _TabletLayout extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;
  final int unread;

  const _TabletLayout({required this.currentIndex, required this.onTabChanged, required this.unread});

  static const _screens = [
    CalendarScreen(),
    TasksScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentIndex,
            onDestinationSelected: onTabChanged,
            extended: MediaQuery.of(context).size.width >= 1000,
            labelType: NavigationRailLabelType.none,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.white, size: 22),
              ),
            ),
            destinations: [
              const NavigationRailDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: Text('Calendar')),
              const NavigationRailDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: Text('Tasks')),
              NavigationRailDestination(
                icon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications_outlined)),
                selectedIcon: Badge(isLabelVisible: unread > 0, label: Text('$unread'), child: const Icon(Icons.notifications)),
                label: const Text('Notifications'),
              ),
              const NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: IndexedStack(index: currentIndex, children: _screens)),
        ],
      ),
    );
  }
}
