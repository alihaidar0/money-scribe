import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/routing/app_routes.dart';
import 'package:money_scribe/core/time/ticker.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/auth/bloc/account_bloc.dart';
import 'package:money_scribe/features/auth/domain/app_lock_repository.dart';
import 'package:money_scribe/features/auth/domain/auth_repository.dart';
import 'package:money_scribe/features/auth/domain/device_key_repository.dart';

/// The Account row of the Settings: the round initial, the name and the email
/// of the signed-in person. It opens the Account screen.
class AccountSettingsTile extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountBloc(
        repository: context.read<AuthRepository>(),
        appLock: context.read<AppLockRepository>(),
        deviceKeys: context.read<DeviceKeyRepository>(),
        ticker: context.read<Ticker>(),
      )..add(const AccountStarted()),
      child: const _AccountTile(),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const new();

  /// Opens the Account screen, and reads the profile again when the person
  /// comes back, because the name may have been changed there.
  Future<void> _open(BuildContext context) async {
    final bloc = context.read<AccountBloc>();
    await context.push<void>(AppRoutes.account);
    // Settings may be gone by now: the person signed out or deleted the
    // account on the Account screen.
    if (!bloc.isClosed) bloc.add(const AccountRetried());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = context.watch<AccountBloc>().state;
    final profile = state.profile;

    if (state.status == AccountStatus.loading && profile == null) {
      return const SkeletonScope(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SkeletonBox(),
        ),
      );
    }
    if (profile == null) {
      // The row still opens the Account screen, which can try again.
      return ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(l10n.accountLoadFailed),
        trailing: const Icon(Icons.refresh),
        onTap: () => context.read<AccountBloc>().add(const AccountRetried()),
      );
    }

    return ListTile(
      leading: ExcludeSemantics(
        child: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(profile.initial),
        ),
      ),
      title: Text(profile.name),
      // An address reads from left to right in any language, but sits at the
      // start of the row.
      subtitle: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(profile.email, textDirection: TextDirection.ltr),
      ),
      trailing: Icon(
        Directionality.of(context) == TextDirection.rtl
            ? Icons.chevron_left
            : Icons.chevron_right,
      ),
      onTap: () => _open(context),
    );
  }
}
