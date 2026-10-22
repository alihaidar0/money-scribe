import 'dart:async';

import 'package:flutter/material.dart';
import 'package:money_scribe/core/challenge/turnstile_page.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Shows the Cloudflare Turnstile widget in a web view and reports its token.
/// The page is our own (`TurnstilePage`), loaded with the address of the
/// server as its base, which is the host the site key allows.
class TurnstileWebView extends StatefulWidget {
  const new({
    required this.siteKey,
    required this.baseUrl,
    required this.action,
    required this.language,
    required this.dark,
    required this.onSolved,
    required this.onFailed,
    super.key,
  });

  final String siteKey;

  /// The address of the server, such as `https://api.example.com`.
  final String baseUrl;
  final String action;

  /// `en` or `ar`: the language of the widget.
  final String language;
  final bool dark;
  final ValueChanged<String> onSolved;
  final VoidCallback onFailed;

  /// The height the widget needs (it is 65 logical pixels high).
  static const height = 80.0;

  @override
  State<TurnstileWebView> createState() => _TurnstileWebViewState();
}

class _TurnstileWebViewState extends State<TurnstileWebView> {
  late final WebViewController _controller;
  var _loaded = false;
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    unawaited(_configure());
  }

  /// Sets the web view up and loads the page. The channel and the navigation
  /// rules are in place before the page loads.
  Future<void> _configure() async {
    final page = Uri.parse(widget.baseUrl);
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.transparent);
    await _controller.addJavaScriptChannel(
      TurnstilePage.channel,
      onMessageReceived: (message) => _onMessage(message.message),
    );
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) {
          final url = Uri.tryParse(request.url);
          final allowed =
              url != null &&
              TurnstilePage.allowsNavigation(
                url,
                isMainFrame: request.isMainFrame,
                page: page,
              );
          return allowed
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onWebResourceError: (error) {
          // A failed picture or frame inside the page is not the page.
          if (error.isForMainFrame ?? true) _fail();
        },
      ),
    );
    await _controller.loadHtmlString(
      TurnstilePage.html(
        siteKey: widget.siteKey,
        action: widget.action,
        language: widget.language,
        dark: widget.dark,
      ),
      baseUrl: widget.baseUrl,
    );
  }

  void _onMessage(String raw) {
    if (_finished) return;
    switch (TurnstileMessage.parse(raw)) {
      case TurnstileToken(:final token):
        // One solution gives one token: a second message is ignored.
        _finished = true;
        widget.onSolved(token);
      case TurnstileError():
        _fail();
      case null:
        break;
    }
  }

  void _fail() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onFailed();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TurnstileWebView.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          WebViewWidget(controller: _controller),
          if (!_loaded)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
