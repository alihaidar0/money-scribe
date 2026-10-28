import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/widgets/category_icons.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/icon_circle.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/features/transactions/bloc/categories_bloc.dart';
import 'package:money_scribe/features/transactions/domain/categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';
import 'package:money_scribe/features/transactions/presentation/category_names.dart';
import 'package:money_scribe/features/transactions/presentation/widgets/category_sheet.dart';

/// ST-4: the categories: the built-in ones, which cannot be changed, and the
/// ones the person made, which open in a sheet to be changed or deleted
/// (ST-4b). The button adds one.
class CategoriesScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CategoriesBloc(repository: context.read<CategoriesRepository>())
            ..add(const CategoriesStarted()),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<CategoriesBloc>();
    final status = context.select<CategoriesBloc, CategoriesStatus>(
      (bloc) => bloc.state.status,
    );

    return MultiBlocListener(
      listeners: [
        BlocListener<CategoriesBloc, CategoriesState>(
          listenWhen: (previous, current) =>
              previous.failedAction != current.failedAction &&
              current.failedAction != null,
          listener: (context, state) {
            final action = state.failedAction;
            if (action == null) return;
            showFailureSnackBar(
              context,
              action is CategoryDeleted
                  ? l10n.couldNotDelete
                  : l10n.couldNotSave,
              onRetry: () => bloc.add(action),
            );
          },
        ),
        BlocListener<CategoriesBloc, CategoriesState>(
          listenWhen: (previous, current) =>
              previous.staleAction != current.staleAction &&
              current.staleAction != null,
          listener: (context, state) {
            final action = state.staleAction;
            if (action == null) return;
            // A category that is gone has nothing to apply the change to.
            final id = switch (action) {
              CategoryChanged(:final id) || CategoryDeleted(:final id) => id,
              _ => null,
            };
            final gone = !state.categories.any((category) => category.id == id);
            showFailureSnackBar(
              context,
              l10n.itemChangedElsewhere,
              actionLabel: l10n.applyAgainAction,
              onRetry: gone ? null : () => bloc.add(action),
            );
          },
        ),
        BlocListener<CategoriesBloc, CategoriesState>(
          listenWhen: (previous, current) =>
              previous.refusal != current.refusal && current.refusal != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(switch (state.refusal) {
                    CategoryRefusal.nameTaken => l10n.categoryNameTaken,
                    CategoryRefusal.limitReached => l10n.categoryLimitReached,
                    null => '',
                  }),
                ),
              );
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.categoriesTitle)),
        floatingActionButton: status == CategoriesStatus.ready
            ? FloatingActionButton.extended(
                heroTag: null,
                onPressed: () => _add(context),
                icon: const Icon(LucideIcons.plus),
                label: Text(l10n.addCategoryAction),
              )
            : null,
        body: switch (status) {
          CategoriesStatus.loading => const _Skeleton(),
          CategoriesStatus.noConnection => FailureView(
            kind: FailureKind.noConnection,
            onRetry: () => bloc.add(const CategoriesRetried()),
          ),
          CategoriesStatus.failure => FailureView(
            kind: FailureKind.error,
            errorTitle: l10n.categoriesLoadFailed,
            onRetry: () => bloc.add(const CategoriesRetried()),
          ),
          CategoriesStatus.ready => const _List(),
        },
      ),
    );
  }

  Future<void> _add(BuildContext context) async {
    final bloc = context.read<CategoriesBloc>();
    final result = await showCategorySheet(
      context,
      takenNames: _takenNames(context, bloc.state.categories),
    );
    if (result is CategorySheetSaved) bloc.add(CategoryAdded(result.draft));
  }
}

/// The names a category cannot take, in lower case: those of the built-in
/// ones, and of the person's own except the one of [except].
Set<String> _takenNames(
  BuildContext context,
  List<TransactionCategory> categories, {
  String? except,
}) {
  return {
    ...context.l10n.reservedCategoryNames(categories),
    for (final category in categories)
      if (category.isCustom && category.id != except)
        category.name.toLowerCase(),
  };
}

class _List extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final categories = context
        .select<CategoriesBloc, List<TransactionCategory>>(
          (bloc) => bloc.state.categories,
        );

    return ListView(
      // Room under the last row for the button.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CategoryRow(category: category),
          ),
      ],
    );
  }
}

/// A category: its icon and name. A built-in one says "Default" and does
/// nothing; one the person made has an edit icon and opens its sheet.
class _CategoryRow extends StatelessWidget {
  const new({required this.category});

  final TransactionCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final custom = category.isCustom;

    return Semantics(
      button: custom,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: custom ? () => _edit(context) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
              child: Row(
                children: [
                  IconCircle(icon: categoryIcon(category.icon), size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.categoryName(category),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  if (custom)
                    IconButton(
                      icon: const Icon(LucideIcons.pencil),
                      tooltip: l10n.editItemTooltip(
                        name: l10n.categoryName(category),
                      ),
                      onPressed: () => _edit(context),
                    )
                  else
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Text(
                        l10n.categoryDefaultLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<CategoriesBloc>();
    final result = await showCategorySheet(
      context,
      category: category,
      takenNames: _takenNames(
        context,
        bloc.state.categories,
        except: category.id,
      ),
    );
    switch (result) {
      case CategorySheetSaved(:final draft):
        bloc.add(CategoryChanged(category.id, draft));
      case CategorySheetDeleted():
        bloc.add(CategoryDeleted(category.id));
      case null:
        break;
    }
  }
}

class _Skeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          for (var i = 0; i < 7; i++) ...[
            const SkeletonBox(),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
