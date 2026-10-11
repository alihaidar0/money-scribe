import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/core/preferences/preferences_provider.dart';
import 'package:money_scribe/features/notifications/application/push_messaging_providers.dart';
import 'package:money_scribe/features/notifications/data/push_messaging_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  final pushMessaging = await createPushMessagingRepository();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        pushMessagingRepositoryProvider.overrideWithValue(pushMessaging),
      ],
      child: const MoneyScribeApp(),
    ),
  );
}
