import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

/// The frame around the five top-level screens: a navigation bar below 840 dp
/// (phones) and a navigation rail from 840 dp (tablets and the web), the
/// expanded window size class of `docs/DESIGN.md`, section 7.
class AppShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  /// The width from which the rail replaces the bar.
  static const expandedWidth = 840.0;

  final StatefulNavigationShell navigationShell;

  void _select(int index) {
    // Pressing the tab already shown goes back to the first screen of that
    // tab.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destinations = [
      _Destination(
        LucideIcons.layoutDashboard,
        LucideIcons.layoutDashboard,
        l10n.overviewTitle,
      ),
      _Destination(
        LucideIcons.banknote,
        LucideIcons.banknote,
        l10n.salaryTitle,
      ),
      _Destination(
        LucideIcons.receiptText,
        LucideIcons.receiptText,
        l10n.transactionsTitle,
      ),
      _Destination(
        LucideIcons.handshake,
        LucideIcons.handshake,
        l10n.debtsTitle,
      ),
      _Destination(
        LucideIcons.chartColumn,
        LucideIcons.chartColumn,
        l10n.reportsTitle,
      ),
    ];
    final isExpanded = MediaQuery.sizeOf(context).width >= expandedWidth;

    if (isExpanded) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _select,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _Destination {
  const new(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
