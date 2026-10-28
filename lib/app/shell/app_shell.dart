import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lucide_icons_flutter/lucide_icons_600.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

/// The frame around the five top-level screens: a floating navigation bar below
/// 840 dp (phones) and a navigation rail from 840 dp (tablets and the web), the
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
    final items = [
      NavigationItem(
        icon: LucideIcons.layoutDashboard,
        selectedIcon: LucideIcons600.layoutDashboard,
        label: l10n.overviewTitle,
      ),
      NavigationItem(
        icon: LucideIcons.banknote,
        selectedIcon: LucideIcons600.banknote,
        label: l10n.salaryTitle,
      ),
      NavigationItem(
        icon: LucideIcons.receiptText,
        selectedIcon: LucideIcons600.receiptText,
        label: l10n.transactionsTitle,
      ),
      NavigationItem(
        icon: LucideIcons.handshake,
        selectedIcon: LucideIcons600.handshake,
        label: l10n.debtsTitle,
      ),
      NavigationItem(
        icon: LucideIcons.chartColumn,
        selectedIcon: LucideIcons600.chartColumn,
        label: l10n.reportsTitle,
      ),
    ];
    final isExpanded = MediaQuery.sizeOf(context).width >= expandedWidth;

    if (isExpanded) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 0, 12),
                // The rail is a rounded card, like the floating bar of phones.
                child: Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: NavigationRail(
                    backgroundColor: Colors.transparent,
                    minWidth: 96,
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final item in items)
                        NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(item.label),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: FloatingNavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onSelected: _select,
        items: items,
      ),
    );
  }
}
