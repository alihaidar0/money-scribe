import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device's simple key-value settings, opened once in `main` so reads are
/// synchronous and the first frame already uses the saved settings.
///
/// Overridden at start-up; reading it without an override is a programming
/// error.
final sharedPreferencesProvider = Provider<SharedPreferencesWithCache>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in the root ProviderScope.',
  ),
);
