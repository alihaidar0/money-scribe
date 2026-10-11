import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

/// Watches every Bloc of the app.
///
/// It logs type names only, never the contents of an event or a state: those
/// can hold personal or financial data, which must never reach a log.
class AppBlocObserver extends BlocObserver {
  const new();

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint('${bloc.runtimeType} received ${event.runtimeType}');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} failed with ${error.runtimeType}');
    super.onError(bloc, error, stackTrace);
  }
}
