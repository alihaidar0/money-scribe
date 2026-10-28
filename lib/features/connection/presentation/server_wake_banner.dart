import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';
import 'package:money_scribe/features/connection/bloc/server_wake_bloc.dart';

/// A note above the screen, for staging builds: the server is starting. The
/// free staging server sleeps after 15 minutes without a request, so the first
/// one afterwards takes about a minute. It never blocks what is underneath, and
/// it disappears as soon as the server answers.
///
/// Put it in a [Stack], above the app.
class ServerWakeBanner extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
      // Taps go through to the screen underneath.
      child: IgnorePointer(
        child: BlocBuilder<ServerWakeBloc, ServerWakeState>(
          buildWhen: (previous, current) =>
              previous.isWaking != current.isWaking,
          builder: (context, state) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: state.isWaking ? const _Note() : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    // The app root sits above the screens, so there is no Material here to give
    // the text its style.
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
          child: MessageBanner(
            icon: LucideIcons.hourglass,
            text: context.l10n.serverStartingMessage,
            tone: BannerTone.info,
          ),
        ),
      ),
    );
  }
}
