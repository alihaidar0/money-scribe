import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:money_scribe/app/app.dart';
import 'package:money_scribe/app/bloc/app_bloc_observer.dart';
import 'package:money_scribe/core/environment/app_environment.dart';
import 'package:money_scribe/features/notifications/data/push_messaging_setup.dart';
import 'package:money_scribe/features/settings/data/shared_preferences_language_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();
  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(),
  );
  final pushMessaging = await createPushMessagingRepository();

  runApp(
    MoneyScribeApp(
      languageRepository: SharedPreferencesLanguageRepository(preferences),
      pushMessagingRepository: pushMessaging,
      environment: AppEnvironment.current,
    ),
  );
}
