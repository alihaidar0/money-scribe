import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/settings/presentation/widgets/language_flag.dart';

/// The bottom sheet that chooses the language: one card per language, with its
/// flag and its name, and a check on [selected]. Closes with the language the
/// person taps, or with `null` when dismissed. A language added to
/// [AppLanguage] shows up here by itself.
Future<AppLanguage?> showLanguageSheet(
  BuildContext context, {
  required AppLanguage selected,
}) {
  return showModalBottomSheet<AppLanguage>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => _LanguageSheet(selected: selected),
  );
}

class _LanguageSheet extends StatelessWidget {
  const new({required this.selected});

  final AppLanguage selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
            child: Semantics(
              header: true,
              child: Text(
                l10n.languageSectionTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: AppLanguage.values.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final language = AppLanguage.values[index];
                return _LanguageCard(
                  language: language,
                  selected: language == selected,
                  onTap: () => Navigator.of(context).pop(language),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const new({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = languageName(context.l10n, language);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outlineVariant,
        width: selected ? 2 : 1,
      ),
    );

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: name,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected
            ? scheme.secondaryContainer
            : scheme.surfaceContainerLow,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  LanguageFlag(language: language),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selected
                            ? scheme.onSecondaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reserved for the check, so the names never shift.
                  SizedBox.square(
                    dimension: 24,
                    child: selected
                        ? Icon(LucideIcons.circleCheck, color: scheme.primary)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
