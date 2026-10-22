import 'dart:convert';

/// What the page of the widget tells the app.
sealed class TurnstileMessage {
  const new();

  /// Reads a message of the page. Anything that is not one of ours is
  /// `null`: the app never acts on what it does not understand.
  static TurnstileMessage? parse(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;

    switch (decoded['event']) {
      case 'token':
        final token = decoded['value'];
        // A token is at most 2,048 characters (Cloudflare's limit).
        if (token is! String || token.isEmpty || token.length > 2048) {
          return const TurnstileError();
        }
        return TurnstileToken(token);
      case 'error':
        return const TurnstileError();
    }
    return null;
  }
}

/// The widget was solved.
final class TurnstileToken extends TurnstileMessage {
  const new(this.token);

  /// Single use; lives five minutes. Never logged.
  final String token;

  @override
  String toString() => 'TurnstileToken';
}

/// The widget could not load or ended in an error. The code Cloudflare gives
/// is of no use to the person, so it is not carried.
final class TurnstileError extends TurnstileMessage {
  const new();

  @override
  String toString() => 'TurnstileError';
}

/// The small page of our own that shows the widget, and the rules for what the
/// web view may open.
abstract final class TurnstilePage {
  /// The name of the JavaScript channel the page reports on.
  static const channel = 'ChallengeChannel';

  /// The only place the widget's script and frames come from.
  static const _cloudflare = 'https://challenges.cloudflare.com';

  /// The page. Every value in it is a constant or has been checked
  /// (`TurnstileConfig`), and is written as JSON all the same.
  static String html({
    required String siteKey,
    required String action,
    required String language,
    required bool dark,
  }) {
    final config = jsonEncode({
      'siteKey': siteKey,
      'action': action,
      'language': language,
      'theme': dark ? 'dark' : 'light',
    }).replaceAll('<', r'\u003c');

    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body { margin: 0; height: 100%; background: transparent; }
  body { display: flex; align-items: center; justify-content: center; }
</style>
<script>
  const config = $config;
  function report(event, value) {
    $channel.postMessage(JSON.stringify({ event: event, value: value }));
  }
  function onTurnstileLoaded() {
    turnstile.render('#widget', {
      sitekey: config.siteKey,
      action: config.action,
      language: config.language,
      theme: config.theme,
      callback: function (token) { report('token', token); },
      'error-callback': function () { report('error'); return true; }
    });
  }
</script>
<script src="$_cloudflare/turnstile/v0/api.js?render=explicit&onload=onTurnstileLoaded"
        async defer onerror="report('error')"></script>
</head>
<body>
<div id="widget"></div>
</body>
</html>
''';
  }

  /// Whether the web view may go to [url]. The page itself loads from the
  /// address of the server, and the widget lives in frames of Cloudflare, so a
  /// frame may open any secure address; the main frame never leaves the page.
  static bool allowsNavigation(
    Uri url, {
    required bool isMainFrame,
    required Uri page,
  }) {
    if (url.scheme == 'about') return true;
    if (isMainFrame) {
      return url.scheme == page.scheme &&
          url.host == page.host &&
          url.port == page.port &&
          (url.path.isEmpty || url.path == '/') &&
          !url.hasQuery;
    }
    return url.scheme == 'https';
  }
}
