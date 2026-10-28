import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/features/salary/bloc/salary_bloc.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_body.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_edit_dialogs.dart';

/// What happened to a saved month opened from the history, so the history can
/// say so when the person comes back.
enum SalaryEditOutcome { saved, deleted }

/// SAL-1b and SAL-1c: a saved month opened from the history to be corrected
/// or deleted. Closes with a [SalaryEditOutcome] once it was saved or deleted;
/// leaving with unsaved changes asks first.
class SalaryEditScreen extends StatelessWidget {
  const new({required this.month, super.key});

  final YearMonth month;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SalaryBloc(
        repository: context.read<SalaryRepository>(),
        now: context.read<Clock>().now,
      )..add(SalaryStarted(month: month)),
      child: const _SalaryEditView(),
    );
  }
}

class _SalaryEditView extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final isEdited = context.select<SalaryBloc, bool>(
      (bloc) => bloc.state.isEdited,
    );

    return BlocListener<SalaryBloc, SalaryState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus ||
          previous.deleteStatus != current.deleteStatus,
      listener: (context, state) {
        if (state.saveStatus == SalarySaveStatus.saved) {
          context.pop(SalaryEditOutcome.saved);
        } else if (state.deleteStatus == SalaryDeleteStatus.deleted) {
          context.pop(SalaryEditOutcome.deleted);
        }
      },
      child: PopScope<Object?>(
        canPop: !isEdited,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final state = context.read<SalaryBloc>().state;
          final discard = await confirmDiscardChanges(
            context,
            month: state.month,
          );
          if (discard && context.mounted) context.pop();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.salaryTitle),
            actions: const [_Menu()],
          ),
          body: const SalaryBody(editing: true),
        ),
      ),
    );
  }
}

enum _MenuAction { deleteMonth }

/// The overflow menu with its one item, Delete month.
class _Menu extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final canDelete = context.select<SalaryBloc, bool>(
      (bloc) =>
          bloc.state.status == SalaryStatus.ready &&
          bloc.state.isSaved &&
          bloc.state.deleteStatus != SalaryDeleteStatus.deleting,
    );
    if (!canDelete) return const SizedBox.shrink();

    return PopupMenuButton<_MenuAction>(
      icon: const Icon(LucideIcons.ellipsisVertical),
      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
      onSelected: (action) => _delete(context),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MenuAction.deleteMonth,
          child: Text(context.l10n.deleteMonthAction),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context) async {
    final bloc = context.read<SalaryBloc>();
    final confirmed = await confirmDeleteMonth(
      context,
      month: bloc.state.month,
    );
    if (confirmed) bloc.add(const SalaryDeleteRequested());
  }
}
