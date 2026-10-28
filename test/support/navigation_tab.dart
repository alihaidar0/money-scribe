import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';

/// The destination with [label] in the floating bar of a phone or in the rail
/// of a tablet.
///
/// The bar shows the label of the selected destination only, so its other
/// destinations are found by their tooltip; the rail shows every label.
Finder navigationTab(String label) {
  final bar = find.byType(FloatingNavigationBar);
  if (bar.evaluate().isNotEmpty) {
    return find.descendant(of: bar, matching: find.byTooltip(label));
  }
  return find.descendant(
    of: find.byType(NavigationRail),
    matching: find.text(label),
  );
}
