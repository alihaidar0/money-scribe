import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/app_icon_image.dart';
import 'package:money_scribe/core/widgets/state_view.dart';

/// A full-screen page of a short flow, such as signing in or the first-start
/// setup: no bottom bar, a back arrow at the start (unless [showBackButton] is
/// off; [onBack] replaces what it does), and a single column with generous
/// whitespace. The column scrolls when it does not fit, for example at a large
/// text size.
///
/// [content] is at the top, or in the middle of the free room when [centered]
/// is set. [bottomChildren] stay at the bottom of the screen while there is
/// room for them, and follow [content] otherwise.
///
/// While [failure] is set, the page shows the "No connection" or "Something
/// went wrong" view instead and keeps the form underneath, so nothing the
/// person typed is lost when they press "Try again" ([onRetry]).
///
/// With [brandPanelWhenWide] (on by default), a window from [wideFrom] dp wide
/// (a tablet or the web) splits in two: a navy panel with the app icon, name
/// and tagline, and the page in a card beside it. A page that shows the brand
/// itself, such as the Welcome screen, turns it off.
class FlowPage extends StatelessWidget {
  const new({
    required this.content,
    this.bottomChildren = const [],
    this.showBackButton = true,
    this.onBack,
    this.centered = false,
    this.brandPanelWhenWide = true,
    this.failure,
    this.onRetry,
    super.key,
  });

  /// The widest the column grows, so forms stay readable on a tablet or the
  /// web.
  static const maxWidth = 440.0;

  /// The window width from which [brandPanelWhenWide] takes effect: the
  /// expanded window size class.
  static const wideFrom = 840.0;

  /// The widest the card of the split layout grows.
  static const cardMaxWidth = 420.0;

  final List<Widget> content;
  final List<Widget> bottomChildren;
  final bool showBackButton;

  /// What the back arrow does instead of closing the page, for a page that can
  /// be the only one, such as Sign in after the server signed the person out.
  final VoidCallback? onBack;

  /// Whether [content] is centred vertically in the free room.
  final bool centered;

  /// Whether a wide window shows the brand panel beside the page.
  final bool brandPanelWhenWide;

  final FailureKind? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final split =
        brandPanelWhenWide && MediaQuery.sizeOf(context).width >= wideFrom;

    final page = _scaffold(split: split);
    if (!split) return page;

    return Scaffold(
      body: Row(
        children: [
          const Expanded(child: _BrandPanel()),
          Expanded(child: page),
        ],
      ),
    );
  }

  Widget _scaffold({required bool split}) {
    final failure = this.failure;

    return Scaffold(
      appBar: failure == null && showBackButton
          ? AppBar(leading: BackButton(onPressed: onBack))
          : null,
      body: SafeArea(
        // The form keeps its size even while hidden, so the stack must not
        // shrink to nothing.
        child: Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: failure != null,
              child: _page(card: split),
            ),
            if (failure != null)
              Positioned.fill(
                child: FailureView(kind: failure, onRetry: onRetry ?? () {}),
              ),
          ],
        ),
      ),
    );
  }

  Widget _page({required bool card}) {
    // With the height unbounded, the column is as tall as its children, but at
    // least as tall as the screen: the free room is shared between the groups.
    final column = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _groups(),
    );

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: card ? cardMaxWidth + 48 : maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
              child: card
                  ? Center(
                      child: Material(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: column,
                        ),
                      ),
                    )
                  : column,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _groups() {
    final main = _group(content);
    final bottom = bottomChildren.isEmpty ? null : _group(bottomChildren);
    const nothing = SizedBox.shrink();

    if (centered) {
      return [nothing, main, bottom ?? nothing];
    }
    return [main, ?bottom];
  }

  Widget _group(List<Widget> widgets) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}

/// The navy half of the split layout: the app icon, the name and the tagline.
class _BrandPanel extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // The same pair as the hero card (`docs/DESIGN.md`).
    final isDark = colors.brightness == Brightness.dark;
    final background = isDark ? colors.primaryContainer : colors.primary;
    final foreground = isDark ? colors.onPrimaryContainer : colors.onPrimary;

    return ColoredBox(
      color: background,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIconImage(size: 96),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    l10n.appTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.welcomeTagline,
                  style: theme.textTheme.bodyLarge?.copyWith(color: foreground),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
