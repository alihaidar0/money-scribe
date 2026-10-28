import 'package:flutter/widgets.dart';

/// Room for the floating navigation bar under a scrolling list.
///
/// The app shell lets the screens reach under the bar, so a list shows through
/// the strip around it and the bar floats over it. The shell passes the height
/// of the bar down as the bottom padding of the media query; a list that sets
/// its own padding adds it with [withBarClearance], so its last row can still
/// be scrolled clear of the bar.
extension BarClearance on EdgeInsets {
  /// This padding with the height of the bar (and of the system bar below it)
  /// added at the bottom.
  EdgeInsets withBarClearance(BuildContext context) {
    return copyWith(bottom: bottom + MediaQuery.paddingOf(context).bottom);
  }
}
