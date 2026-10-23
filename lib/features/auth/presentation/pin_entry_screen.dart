import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/features/auth/bloc/pin_bloc.dart';
import 'package:money_scribe/features/auth/presentation/widgets/pin_page.dart';

/// AUTH-12: open the app with the PIN.
class PinEntryScreen extends StatelessWidget {
  const new({this.returnTo, super.key});

  /// Where the person was, and where the open app goes back to.
  final String? returnTo;

  @override
  Widget build(BuildContext context) {
    return PinPage(
      mode: PinMode.unlock,
      onAccepted: (context) => context.go(AppRoutes.returnTo(returnTo)),
      onSignedOut: (context) => context.go(AppRoutes.signIn),
    );
  }
}
