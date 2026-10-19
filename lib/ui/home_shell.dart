import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_services.dart';
import '../app/providers.dart';
import '../security/lock_controller.dart';
import 'screens/goals/goal_editor_screen.dart';
import 'screens/goals/goals_screen.dart';
import 'screens/month/month_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/today/today_screen.dart';
import 'sheets/quick_add_sheet.dart';

enum HomeTab {
  today('Today', Icons.today_outlined, Icons.today),
  goals('Goals', Icons.savings_outlined, Icons.savings),
  month('Month', Icons.menu_book_outlined, Icons.menu_book),
  reports('Reports', Icons.bar_chart_outlined, Icons.bar_chart);

  const HomeTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

final selectedTabProvider = StateProvider<HomeTab>((ref) => HomeTab.today);

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _railBreakpoint = 600.0;

  bool _upkeepDone = false;

  @override
  void initState() {
    super.initState();
    final lock = ref.read(appServicesProvider).lock;
    lock.addListener(_runUpkeepOnceUnlocked);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runUpkeepOnceUnlocked());
  }

  @override
  void dispose() {
    ref.read(appServicesProvider).lock.removeListener(_runUpkeepOnceUnlocked);
    super.dispose();
  }

  /// Waits for the PIN so the permission prompt never sits on the lock screen.
  Future<void> _runUpkeepOnceUnlocked() async {
    final services = ref.read(appServicesProvider);
    if (_upkeepDone || services.lock.state != AppLockState.unlocked) return;
    _upkeepDone = true;
    await services.notifications.askPermission();
    await ref.read(dailyUpkeepProvider).run(ref.read(todayProvider));
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(selectedTabProvider);
    final wide = MediaQuery.sizeOf(context).width >= _railBreakpoint;
    final body = IndexedStack(
      index: tab.index,
      children: const [TodayScreen(), GoalsScreen(), MonthScreen(), ReportsScreen()],
    );
    return Scaffold(
      body: wide ? Row(children: [_rail(tab), const VerticalDivider(width: 1), Expanded(child: body)]) : body,
      floatingActionButton: _fabFor(tab),
      bottomNavigationBar: wide ? null : _bar(tab),
    );
  }

  void _select(int index) => ref.read(selectedTabProvider.notifier).state = HomeTab.values[index];

  Widget _bar(HomeTab tab) => NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: _select,
        destinations: [
          for (final item in HomeTab.values)
            NavigationDestination(icon: Icon(item.icon), selectedIcon: Icon(item.selectedIcon), label: item.label),
        ],
      );

  Widget _rail(HomeTab tab) => SafeArea(
        child: NavigationRail(
          selectedIndex: tab.index,
          onDestinationSelected: _select,
          labelType: NavigationRailLabelType.all,
          destinations: [
            for (final item in HomeTab.values)
              NavigationRailDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              ),
          ],
        ),
      );

  Widget? _fabFor(HomeTab tab) => switch (tab) {
        HomeTab.today || HomeTab.month => FloatingActionButton.extended(
            heroTag: 'spend',
            onPressed: () => showQuickAdd(context),
            icon: const Icon(Icons.edit),
            label: const Text('Spend'),
            tooltip: 'Write down money spent',
          ),
        HomeTab.goals => FloatingActionButton.extended(
            heroTag: 'goal',
            onPressed: () => Navigator.of(context).push(GoalEditorScreen.route()),
            icon: const Icon(Icons.add),
            label: const Text('New goal'),
          ),
        HomeTab.reports => null,
      };
}
