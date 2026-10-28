import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/features/settings/presentation/widgets/currency_names.dart';

/// ST-9: the bottom sheet that chooses the default currency from the
/// supported ones, starting with [selected]. Closes with the chosen currency
/// when Done is pressed, or with `null` when dismissed.
Future<Currency?> showCurrencySheet(
  BuildContext context, {
  required Currency selected,
}) {
  return showModalBottomSheet<Currency>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) => _CurrencySheet(selected: selected),
  );
}

class _CurrencySheet extends StatefulWidget {
  const new({required this.selected});

  final Currency selected;

  @override
  State<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<_CurrencySheet> {
  late Currency _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Semantics(
              header: true,
              child: Text(
                l10n.defaultCurrencyTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final currency in Currency.values)
                  Semantics(
                    inMutuallyExclusiveGroup: true,
                    checked: currency == _selected,
                    child: ListTile(
                      title: Text(currencyLabel(l10n, currency)),
                      trailing: ExcludeSemantics(
                        child: Icon(
                          currency == _selected
                              ? LucideIcons.circleDot
                              : LucideIcons.circle,
                          color: currency == _selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                      onTap: () => setState(() => _selected = currency),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancelAction),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: Text(l10n.doneAction),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
