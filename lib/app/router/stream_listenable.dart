import 'dart:async';

import 'package:flutter/foundation.dart';

/// Tells the router to look at its redirects again whenever the stream emits,
/// for example when the person signs in or out.
class StreamListenable extends ChangeNotifier {
  new(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
