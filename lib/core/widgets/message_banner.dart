import 'package:flutter/material.dart';

/// How a [MessageBanner] looks.
enum BannerTone {
  /// Something went wrong: `errorContainer`.
  error,

  /// Something to know: `secondaryContainer`.
  info,
}

/// One sentence with an icon on a tonal container, for errors and notices
/// above a form. Screen readers read it out when it appears.
class MessageBanner extends StatelessWidget {
  const new({
    required this.icon,
    required this.text,
    this.tone = BannerTone.error,
    super.key,
  });

  final IconData icon;
  final String text;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      BannerTone.error => (colors.errorContainer, colors.onErrorContainer),
      BannerTone.info => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
