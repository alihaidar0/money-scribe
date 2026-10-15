import 'package:flutter/widgets.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/routing/navigation_extensions.dart';
import 'package:money_scribe/features/auth/bloc/pin_bloc.dart';
import 'package:money_scribe/features/auth/presentation/widgets/pin_page.dart';

/// AUTH-13: choose the PIN of the app lock.
class CreatePinScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return PinPage(
      mode: PinMode.create,
      onAccepted: (context) => context.popOrGo(AppRoutes.settings),
    );
  }
}
