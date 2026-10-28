import 'dart:async';

import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/network/data_change.dart';
import 'package:money_scribe/features/overview/domain/debt_choice.dart';
import 'package:money_scribe/features/overview/domain/month_overview.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';
import 'package:money_scribe/features/reports/domain/debts_report.dart';
import 'package:money_scribe/features/reports/domain/month_report.dart';
import 'package:money_scribe/features/reports/domain/reports_repository.dart';

/// An [OverviewRepository] that answers like [inner] and tells about changes
/// only when the test calls [announce], so a test can choose the kind.
class DrivenChangesOverviewRepository implements OverviewRepository {
  new(this.inner);

  final OverviewRepository inner;
  final _changes = StreamController<DataChange>.broadcast(sync: true);

  void announce(DataChange change) => _changes.add(change);

  @override
  Stream<DataChange> get changes => _changes.stream;

  @override
  Future<MonthOverview?> month(YearMonth month) => inner.month(month);

  @override
  Future<List<DebtChoice>> debtsToRepay() => inner.debtsToRepay();
}

/// A [ReportsRepository] that answers like [inner] and tells about changes
/// only when the test calls [announce], so a test can choose the kind.
class DrivenChangesReportsRepository implements ReportsRepository {
  new(this.inner);

  final ReportsRepository inner;
  final _changes = StreamController<DataChange>.broadcast(sync: true);

  void announce(DataChange change) => _changes.add(change);

  @override
  Stream<DataChange> get changes => _changes.stream;

  @override
  Future<MonthReport?> month(YearMonth month) => inner.month(month);

  @override
  Future<DebtsReport> debts() => inner.debts();
}
