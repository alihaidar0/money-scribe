import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:money_scribe/core/challenge/challenge_view_factory.dart';
import 'package:money_scribe/core/challenge/turnstile_web_view.dart';

/// The real challenge: Cloudflare Turnstile in a web view. It needs the site
/// key of the build and the address of the server (the host the key allows),
/// and a platform with a web view: Android and iOS.
final class TurnstileChallengeViewFactory implements ChallengeViewFactory {
  const new({required this.siteKey, required this.baseUrl});

  /// `null` when the build has no key.
  final String? siteKey;

  /// The address of the server, or `null` when the build has none.
  final String? baseUrl;

  static bool get _platformHasWebView =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  bool get isAvailable =>
      siteKey != null && baseUrl != null && _platformHasWebView;

  @override
  Widget build(
    BuildContext context, {
    required String action,
    required ValueChanged<String> onSolved,
    required VoidCallback onFailed,
    Key? key,
  }) {
    return TurnstileWebView(
      key: key,
      siteKey: siteKey!,
      baseUrl: baseUrl!,
      action: action,
      language: Localizations.localeOf(context).languageCode == 'ar'
          ? 'ar'
          : 'en',
      dark: Theme.of(context).brightness == Brightness.dark,
      onSolved: onSolved,
      onFailed: onFailed,
    );
  }
}
