import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/core/widgets/top_level_screen.dart';
import 'package:money_scribe/features/salary/bloc/salary_bloc.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_body.dart';
import 'package:money_scribe/features/salary/presentation/widgets/salary_history_button.dart';

/// SAL-1, SAL-2, SAL-3, SAL-4, SAL-5, SAL-10 and their empty, loading, error
/// and no-connection states: the salary of a month, calculated as it is
/// typed, and saving it.
///
/// It shows the month of today, or [month] when another screen sends the
/// person here with one (such as "New month" in the history). A different
/// [requestId] asks for [month] again even when it is the same month.
class SalaryScreen extends StatefulWidget {
  const new({this.month, this.requestId, super.key});

  final YearMonth? month;
  final int? requestId;

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen> {
  late final SalaryBloc _bloc = SalaryBloc(
    repository: context.read<SalaryRepository>(),
    now: context.read<Clock>().now,
  )..add(SalaryStarted(month: widget.month));

  @override
  void didUpdateWidget(SalaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final month = widget.month;
    if (month != null &&
        (month != oldWidget.month || widget.requestId != oldWidget.requestId)) {
      _bloc.add(SalaryMonthSelected(month));
    }
  }

  @override
  void dispose() {
    unawaited(_bloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: TopLevelScreen(
        title: context.l10n.salaryTitle,
        actions: const [SalaryHistoryButton()],
        body: const SalaryBody(editing: false),
      ),
    );
  }
}
