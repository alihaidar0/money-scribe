import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';

/// The frame of the five top-level screens: a small app bar whose title is the
/// screen name, with the Settings gear at the end after any other [actions].
/// The navigation bar belongs to the app shell around it, and floats over the
/// bottom of the body.
class TopLevelScreen extends StatelessWidget {
  const new({
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          ...actions,
          IconButton(
            icon: const Icon(LucideIcons.settings),
            tooltip: context.l10n.settingsTitle,
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: body,
      floatingActionButton: floatingActionButton == null
          ? null
          : Padding(
              // The shell lets the body reach under the navigation bar, and a
              // scaffold only lifts its button over the system bar: the rest
              // of the bar's height is added here.
              padding: EdgeInsets.only(
                bottom: math.max(
                  0,
                  MediaQuery.paddingOf(context).bottom -
                      MediaQuery.viewPaddingOf(context).bottom,
                ),
              ),
              child: floatingActionButton,
            ),
    );
  }
}
