import 'dart:async';

import 'package:flutter/material.dart';

/// Loads a screen's content again when the person pulls its list down at the
/// top. [onRefresh] asks the screen's Bloc to load without the loading state
/// and hands it a [Completer] to complete when it is done, which ends the
/// spinner.
///
/// The list inside must scroll even when it is short: give it
/// [AlwaysScrollableScrollPhysics].
class PullToRefresh extends StatelessWidget {
  const new({required this.onRefresh, required this.child, super.key});

  final void Function(Completer<void> done) onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        final done = Completer<void>();
        onRefresh(done);
        return done.future;
      },
      child: child,
    );
  }
}
