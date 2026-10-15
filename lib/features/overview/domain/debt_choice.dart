import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/money/money.dart';

/// A debt that can still be repaid, as offered when a repayment is added from
/// the Overview.
final class DebtChoice extends Equatable {
  const new({
    required this.id,
    required this.person,
    required this.direction,
    required this.remaining,
    required this.status,
  });

  final String id;
  final String person;
  final DebtDirection direction;

  /// What is still to be repaid.
  final Money remaining;

  /// [DebtStatus.open] or [DebtStatus.overdue].
  final DebtStatus status;

  @override
  List<Object> get props => [id, person, direction, remaining, status];
}
