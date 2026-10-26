part of 'debt_details_bloc.dart';

enum DebtDetailsStatus {
  /// The debt is being loaded.
  loading,

  /// The debt is shown.
  ready,

  /// There is no such debt.
  notFound,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

enum DebtDeleteStatus {
  /// Nothing to report.
  idle,

  /// The debt is being deleted on the server.
  deleting,

  /// The debt was deleted.
  deleted,

  /// The debt could not be deleted; it is still there.
  failed,
}

final class DebtDetailsState extends Equatable {
  const new({
    required this.debtId,
    required this.today,
    this.status = DebtDetailsStatus.loading,
    this.debt,
    this.failedAction,
    this.deleteStatus = DebtDeleteStatus.idle,
    this.refusal,
    this.refusedRemaining,
    this.changedElsewhere = false,
  });

  final String debtId;
  final DebtDetailsStatus status;

  /// The debt, once it is loaded.
  final Debt? debt;

  /// The day of today, which decides whether the debt is overdue.
  final DateTime today;

  /// The last repayment change that the server did not accept, so the screen
  /// can offer to try it again. `null` once something else was done.
  final DebtDetailsEvent? failedAction;

  final DebtDeleteStatus deleteStatus;

  /// Why the server refused the last change, until something else is done.
  final DebtRefusal? refusal;

  /// What the server said is left to repay, when it refused a repayment for
  /// being more than that.
  final Money? refusedRemaining;

  /// Whether the last change was not applied because the debt had been changed
  /// on another device; the debt shown is the one read again.
  final bool changedElsewhere;

  DebtDetailsState copyWith({
    DebtDetailsStatus? status,
    Debt? debt,
    DateTime? today,
    DebtDetailsEvent? failedAction,
    bool clearFailedAction = false,
    DebtDeleteStatus? deleteStatus,
    DebtRefusal? refusal,
    Money? refusedRemaining,
    bool? changedElsewhere,
    bool clearNotices = false,
  }) {
    return DebtDetailsState(
      debtId: debtId,
      status: status ?? this.status,
      debt: debt ?? this.debt,
      today: today ?? this.today,
      failedAction: clearFailedAction
          ? null
          : failedAction ?? this.failedAction,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      refusal: clearNotices ? null : refusal ?? this.refusal,
      refusedRemaining: clearNotices
          ? null
          : refusedRemaining ?? this.refusedRemaining,
      changedElsewhere:
          !clearNotices && (changedElsewhere ?? this.changedElsewhere),
    );
  }

  @override
  List<Object?> get props => [
    debtId,
    status,
    debt,
    today,
    failedAction,
    deleteStatus,
    refusal,
    refusedRemaining,
    changedElsewhere,
  ];
}
