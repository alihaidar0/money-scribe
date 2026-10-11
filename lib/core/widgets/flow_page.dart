import 'package:flutter/material.dart';
import 'package:money_scribe/core/widgets/state_view.dart';

/// A full-screen page of a short flow, such as signing in or the first-start
/// setup: no bottom bar, a back arrow at the start (unless [showBackButton] is
/// off), and a single column with generous whitespace. The column scrolls when
/// it does not fit, for example at a large text size.
///
/// [content] is at the top, or in the middle of the free room when [centered]
/// is set. [bottomChildren] stay at the bottom of the screen while there is
/// room for them, and follow [content] otherwise.
///
/// While [failure] is set, the page shows the "No connection" or "Something
/// went wrong" view instead and keeps the form underneath, so nothing the
/// person typed is lost when they press "Try again" ([onRetry]).
class FlowPage extends StatelessWidget {
  const new({
    required this.content,
    this.bottomChildren = const [],
    this.showBackButton = true,
    this.centered = false,
    this.failure,
    this.onRetry,
    super.key,
  });

  /// The widest the column grows, so forms stay readable on a tablet or the
  /// web.
  static const maxWidth = 440.0;

  final List<Widget> content;
  final List<Widget> bottomChildren;
  final bool showBackButton;

  /// Whether [content] is centred vertically in the free room.
  final bool centered;

  final FailureKind? failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = this.failure;

    return Scaffold(
      appBar: failure == null && showBackButton
          ? AppBar(leading: const BackButton())
          : null,
      body: SafeArea(
        // The form keeps its size even while hidden, so the stack must not
        // shrink to nothing.
        child: Stack(
          fit: StackFit.expand,
          children: [
            Offstage(offstage: failure != null, child: _page()),
            if (failure != null)
              Positioned.fill(
                child: FailureView(kind: failure, onRetry: onRetry ?? () {}),
              ),
          ],
        ),
      ),
    );
  }

  Widget _page() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minHeight: constraints.maxHeight,
            ),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
              // With the height unbounded, the column is as tall as its
              // children, but at least as tall as the screen: the free room
              // is shared between the groups.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _groups(),
              ),
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
