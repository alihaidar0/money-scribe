import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension LeaveScreen on BuildContext {
  /// Goes back to the screen before this one. When there is none, because the
  /// screen was opened from an address, goes to [fallback] instead.
  void leave({required String fallback}) {
    if (canPop()) {
      pop();
    } else {
      go(fallback);
    }
  }
}
