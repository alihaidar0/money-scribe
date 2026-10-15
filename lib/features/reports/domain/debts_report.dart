import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/money/money.dart';

/// A debt that is not settled, as the debts report lists it.
final class DebtReportItem extends Equatable {
  const new({
    required this.id,
    required this.person,
    required this.direction,
    required this.remaining,
    required this.status,
    this.dueDate,
  });

  final String id;
  final String person;
  final DebtDirection direction;

  /// What is still to be repaid.
  final Money remaining;

  /// [DebtStatus.open] or [DebtStatus.overdue].
  final DebtStatus status;
  final DateTime? dueDate;

  @override
  List<Object?> get props => [
    id,
    person,
    direction,
    remaining,
    status,
    dueDate,
  ];
}

/// Where the debts stand: what is owed to the person, what they owe, and the
/// debts that are not settled, the overdue ones apart.
final class DebtsReport extends Equatable {
  const new({
    required this.owedToYou,
    required this.youOwe,
    this.overdue = const [],
    this.open = const [],
  });

  /// What others still owe the person.
  final Money owedToYou;

  /// What the person still owes.
  final Money youOwe;

  /// The debts whose due day has passed.
  final List<DebtReportItem> overdue;

  /// The debts still being repaid on time.
  final List<DebtReportItem> open;

  /// Whether there is no debt to report.
  bool get isEmpty => overdue.isEmpty && open.isEmpty;

  @override
  List<Object> get props => [owedToYou, youOwe, overdue, open];
}
