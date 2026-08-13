import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fintrack/core/extensions/context_extensions.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: l10n.home),
          NavigationDestination(icon: const Icon(Icons.swap_vert_rounded), selectedIcon: const Icon(Icons.swap_vert_rounded), label: l10n.transactions),
          NavigationDestination(icon: const Icon(Icons.pie_chart_outline), selectedIcon: const Icon(Icons.pie_chart_rounded), label: l10n.budget),
          NavigationDestination(icon: const Icon(Icons.bar_chart_outlined), selectedIcon: const Icon(Icons.bar_chart_rounded), label: l10n.reports),
          NavigationDestination(icon: const Icon(Icons.more_horiz), selectedIcon: const Icon(Icons.more_horiz), label: l10n.more),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0x1AEF4444), child: Icon(Icons.north_east_rounded, color: Color(0xFFEF4444))),
                  title: Text(l10n.addExpense),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/transactions/new?type=EXPENSE');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0x1A10B981), child: Icon(Icons.south_west_rounded, color: Color(0xFF10B981))),
                  title: Text(l10n.addIncome),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/transactions/new?type=INCOME');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
