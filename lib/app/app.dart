import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_scribe/app/router/app_router.dart';

class MoneyScribeApp extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Money Scribe',
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
