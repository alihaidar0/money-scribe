/// The public site key of the Cloudflare Turnstile widget, as the build says.
/// Like the server address it is a build-time value
/// (`--dart-define-from-file=.env.<environment>`, see `docs/backend-api.md`)
/// kept out of the repository. The key is public once the app is built; the
/// secret key belongs to the server alone and never comes near the app. A
/// build without a key cannot show the bot challenge.
final class TurnstileConfig {
  const new _(this.siteKey);

  static const _define = String.fromEnvironment('TURNSTILE_SITE_KEY');

  /// The site key of this build, or `null` when the build has none.
  static final TurnstileConfig? current = parse(_define);

  /// What a site key looks like: letters, digits, `-` and `_`. The page of the
  /// widget is built with it, so nothing else is accepted.
  static final _shape = RegExp(r'^[0-9A-Za-z_-]{1,64}$');

  final String siteKey;

  /// Reads the build-time value. An empty value means "no key" and gives
  /// `null`. A value that is not a site key throws a [FormatException] at
  /// start, so a mistake in a build is found at once. The message never
  /// repeats the value.
  static TurnstileConfig? parse(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    if (!_shape.hasMatch(text)) {
      throw const FormatException(
        'TURNSTILE_SITE_KEY is not a Cloudflare Turnstile site key.',
      );
    }
    return TurnstileConfig._(text);
  }
}
