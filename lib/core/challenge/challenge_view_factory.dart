import 'package:flutter/widgets.dart';

/// The action name the server expects on the sign-in challenge: the widget is
/// created with it and the server checks it on the token.
const signInChallengeAction = 'sign_in';

/// Builds the widget that solves a bot challenge and reports its token. The
/// screens know only this interface: the real one shows Cloudflare Turnstile
/// in a web view, the demo one has a button, and tests have no web view.
abstract interface class ChallengeViewFactory {
  /// Whether this build, on this platform, can show a challenge at all. When it
  /// cannot, the person is told to try again later.
  bool get isAvailable;

  /// The widget for [action]. [onSolved] gets the token, once per solution.
  /// [onFailed] says the challenge could not be shown or ended in an error;
  /// the caller offers to try again by building a new widget with another
  /// [key].
  Widget build(
    BuildContext context, {
    required String action,
    required ValueChanged<String> onSolved,
    required VoidCallback onFailed,
    Key? key,
  });
}
