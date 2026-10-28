import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/challenge/challenge_view_factory.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/message_banner.dart';

/// AUTH-2f: the bottom sheet with the bot challenge the server asks for after
/// repeated failed sign-ins. Closes with the token of the solved challenge, or
/// with `null` when the person closes it.
///
/// [rejected] says the token of the last challenge was refused, so this is a
/// new one. Nothing is sent from here: the screen sends the token once.
Future<String?> showSignInChallengeSheet(
  BuildContext context, {
  required ChallengeViewFactory factory,
  bool rejected = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // A drag would fight with the widget inside; the Cancel button, the back
    // gesture and a tap outside close the sheet.
    enableDrag: false,
    builder: (sheetContext) =>
        _SignInChallengeSheet(factory: factory, rejected: rejected),
  );
}

class _SignInChallengeSheet extends StatefulWidget {
  const new({required this.factory, required this.rejected});

  final ChallengeViewFactory factory;
  final bool rejected;

  @override
  State<_SignInChallengeSheet> createState() => _SignInChallengeSheetState();
}

class _SignInChallengeSheetState extends State<_SignInChallengeSheet> {
  /// Changes to build the challenge again after it failed.
  var _attempt = 0;
  var _failed = false;
  var _solved = false;

  void _onSolved(String token) {
    // One solution gives one token.
    if (_solved) return;
    _solved = true;
    Navigator.of(context).pop(token);
  }

  void _onFailed() {
    if (mounted) setState(() => _failed = true);
  }

  void _tryAgain() {
    setState(() {
      _failed = false;
      _attempt++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final available = widget.factory.isAvailable;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.challengeTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.challengeBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (widget.rejected && !_failed && available) ...[
              MessageBanner(
                icon: LucideIcons.circleAlert,
                text: l10n.challengeRejected,
              ),
              const SizedBox(height: 16),
            ],
            if (!available)
              MessageBanner(
                icon: LucideIcons.info,
                tone: BannerTone.info,
                text: l10n.challengeUnavailable,
              )
            else if (_failed) ...[
              MessageBanner(
                icon: LucideIcons.circleAlert,
                text: l10n.challengeLoadFailed,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _tryAgain,
                child: Text(l10n.tryAgain),
              ),
            ] else
              Center(
                child: widget.factory.build(
                  context,
                  key: ValueKey(_attempt),
                  action: signInChallengeAction,
                  onSolved: _onSolved,
                  onFailed: _onFailed,
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancelAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
