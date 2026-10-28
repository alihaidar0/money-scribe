import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/app_text_field.dart';
import 'package:money_scribe/core/widgets/category_icons.dart';
import 'package:money_scribe/core/widgets/confirm_dialogs.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

/// What the person did in the sheet that adds or changes a category.
sealed class CategorySheetResult {
  const new();
}

/// Save: the category as it was typed.
final class CategorySheetSaved extends CategorySheetResult {
  const new(this.draft);

  final CategoryDraft draft;
}

/// Delete, after the person confirmed it.
final class CategorySheetDeleted extends CategorySheetResult {
  const new();
}

/// ST-4b: the bottom sheet that adds a category, or with [category] changes
/// it, which also offers Delete. Closes with what was done, or with `null`
/// when dismissed. [takenNames] are the names, in lower case, that the
/// sheet refuses: the other custom categories' and every built-in category's,
/// in the language of the app and in English, because the server accepts a
/// name once and only knows the English ones.
Future<CategorySheetResult?> showCategorySheet(
  BuildContext context, {
  TransactionCategory? category,
  Set<String> takenNames = const {},
}) {
  return showModalBottomSheet<CategorySheetResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    // Over the navigation bar too, which stays dimmed and inactive.
    useRootNavigator: true,
    builder: (sheetContext) =>
        _CategorySheet(category: category, takenNames: takenNames),
  );
}

class _CategorySheet extends StatefulWidget {
  const new({required this.category, required this.takenNames});

  final TransactionCategory? category;
  final Set<String> takenNames;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.category?.name ?? '',
  );
  late CategoryIcon _icon = widget.category?.icon ?? CategoryIcon.choices.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  CategoryDraft? get _draft =>
      CategoryDraft.tryCreate(name: _name.text, icon: _icon);

  bool get _nameTaken =>
      widget.takenNames.contains(_name.text.trim().toLowerCase());

  Future<void> _delete() async {
    final category = widget.category;
    if (category == null) return;
    final l10n = context.l10n;
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteCategoryTitle,
      message: l10n.deleteCategoryMessage(name: category.name),
    );
    if (confirmed && mounted) {
      Navigator.of(context).pop(const CategorySheetDeleted());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final draft = _draft;
    final nameTaken = _nameTaken;
    final editing = widget.category != null;

    return SafeArea(
      child: SingleChildScrollView(
        // Above the keyboard.
        padding: EdgeInsetsDirectional.fromSTEB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                editing ? l10n.editCategoryTitle : l10n.addCategoryTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _name,
              label: l10n.nameLabel,
              errorText: nameTaken ? l10n.categoryNameTaken : null,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                l10n.categoryIconLabel,
                style: theme.textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in CategoryIcon.choices)
                  _IconChoice(
                    icon: icon,
                    selected: icon == _icon,
                    onPressed: () => setState(() => _icon = icon),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: editing
                  ? WrapAlignment.spaceBetween
                  : WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                if (editing)
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _delete,
                    child: Text(l10n.deleteAction),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancelAction),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: draft == null || nameTaken
                          ? null
                          : () =>
                                Navigator.of(context)
                                    .pop(CategorySheetSaved(draft)),
                      child: Text(l10n.saveAction),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One picture to choose for a category: a soft circle, outlined and checked
/// while chosen, so the choice does not rest on colour alone.
class _IconChoice extends StatelessWidget {
  const new({
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final CategoryIcon icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: _name(context, icon),
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerHigh,
        shape: CircleBorder(
          side: BorderSide(
            color: selected ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  categoryIcon(icon),
                  color: selected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
                if (selected)
                  PositionedDirectional(
                    end: 4,
                    top: 4,
                    child: Icon(
                      LucideIcons.circleCheck,
                      size: 16,
                      color: colors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _name(BuildContext context, CategoryIcon icon) {
    final l10n = context.l10n;

    return switch (icon) {
      CategoryIcon.gifts => l10n.categoryIconGifts,
      CategoryIcon.health => l10n.categoryIconHealth,
      CategoryIcon.entertainment => l10n.categoryIconEntertainment,
      CategoryIcon.shopping => l10n.categoryIconShopping,
      CategoryIcon.education => l10n.categoryIconEducation,
      CategoryIcon.travel => l10n.categoryIconTravel,
      CategoryIcon.subscriptions => l10n.categoryIconSubscriptions,
      CategoryIcon.other => l10n.categoryIconOther,
      _ => icon.name,
    };
  }
}
