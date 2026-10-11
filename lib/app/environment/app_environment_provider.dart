import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_scribe/app/environment/app_environment.dart';

/// The environment of this build; tests override it to try the other one.
final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => AppEnvironment.current,
);
