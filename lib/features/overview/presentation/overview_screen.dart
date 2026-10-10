import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/app/router/app_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';

class OverviewScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.overviewTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: Center(child: Text(l10n.overviewEmpty)),
    );
  }
}
