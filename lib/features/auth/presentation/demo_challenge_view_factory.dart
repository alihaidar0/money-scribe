import 'package:flutter/material.dart';
import 'package:money_scribe/core/challenge/challenge_view_factory.dart';

/// The bot challenge of a build with the fake account: a button that "solves"
/// it, so the demo panel can force the challenge without a server or a web
/// view. It goes away with the fake account.
final class DemoChallengeViewFactory implements ChallengeViewFactory {
  const new();

  @override
  bool get isAvailable => true;

  @override
  Widget build(
    BuildContext context, {
    required String action,
    required ValueChanged<String> onSolved,
    required VoidCallback onFailed,
    Key? key,
  }) {
    return OutlinedButton(
      key: key,
      onPressed: () => onSolved('demo-token'),
      child: const Text('I am not a robot (demo)'),
    );
  }
}
