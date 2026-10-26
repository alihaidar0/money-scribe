part of 'debt_form_bloc.dart';

enum DebtFormStatus {
  /// The debt to change is being loaded.
  loading,

  /// The form can be filled in.
  ready,

  /// The debt to change does not exist.
  notFound,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

enum DebtFormSaveStatus {
  /// Nothing to report: not saved yet, or edited since.
  idle,

  /// The debt is being sent to the server.
  saving,

  /// The debt was saved.
  saved,

  /// The debt could not be saved; what was typed is kept.
  failed,

  /// The debt was changed on another device since it was loaded; nothing was
  /// saved, and it is being loaded again.
  stale,

  /// The server refused the debt for a reason the person can act on, which
  /// [DebtFormState.refusal] names; what was typed is kept.
  refused,
}

/// What can be typed into the form.
final class DebtFormValues extends Equatable {
  const new({
    required this.startDate,
    this.direction = DebtDirection.lent,
    this.person = '',
    this.amountText = '',
    this.dueDate,
    this.note = '',
  });

  final DebtDirection direction;
  final String person;

  /// The amount as typed, such as `10000.00`.
  final String amountText;
  final DateTime startDate;
  final DateTime? dueDate;
  final String note;

  DebtFormValues copyWith({
    DebtDirection? direction,
    String? person,
    String? amountText,
    DateTime? startDate,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? note,
  }) {
    return DebtFormValues(
      direction: direction ?? this.direction,
      person: person ?? this.person,
      amountText: amountText ?? this.amountText,
      startDate: startDate ?? this.startDate,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
    direction,
    person,
    amountText,
    startDate,
    dueDate,
    note,
  ];
}

final class DebtFormState extends Equatable {
  const new({
    required this.values,
    required this.baseline,
    this.debtId,
    this.status = DebtFormStatus.loading,
    this.repaid,
    this.lastRepaymentDate,
    this.version,
    this.currency = Currency.rub,
    this.saveStatus = DebtFormSaveStatus.idle,
    this.refusal,
  });

  final DebtFormStatus status;

  /// The id of the debt being changed, or `null` for a new one.
  final String? debtId;

  final DebtFormValues values;

  /// What the form held when it was loaded, to tell whether it was edited.
  final DebtFormValues baseline;

  /// What was already repaid of the debt being changed, which the amount
  /// cannot fall below.
  final Money? repaid;

  /// The day of the latest repayment of the debt being changed, which the
  /// start day cannot go past.
  final DateTime? lastRepaymentDate;

  /// The version of the debt being changed, as the server holds it, or `null`
  /// for a new debt.
  final int? version;

  /// The currency of the amount: the default one for a new debt, and the
  /// debt's own, which cannot be changed, for one being changed.
  final Currency currency;
  final DebtFormSaveStatus saveStatus;

  /// Why the server refused the debt, while [saveStatus] is
  /// [DebtFormSaveStatus.refused].
  final DebtRefusal? refusal;

  /// Whether an existing debt is being changed.
  bool get isEditing => debtId != null;

  /// Whether the form differs from what was loaded.
  bool get isEdited => values != baseline;

  /// The amount as a number, or `null` while it is not one.
  Money? get amount => Money.tryParse(values.amountText, currency);

  /// Whether the amount is less than what was already repaid.
  bool get amountBelowRepaid {
    final amount = this.amount;
    final repaid = this.repaid;
    return amount != null && repaid != null && amount < repaid;
  }

  /// Whether the debt is due before it starts.
  bool get dueBeforeStart {
    final due = values.dueDate;
    return due != null && due.isBefore(values.startDate);
  }

  /// Whether the debt would start after one of its repayments.
  bool get startAfterRepayment {
    final last = lastRepaymentDate;
    return last != null && values.startDate.isAfter(last);
  }

  /// What was typed as a debt, or `null` while it is incomplete or wrong.
  DebtDraft? get draft {
    if (amountBelowRepaid || startAfterRepayment) return null;
    return DebtDraft.tryCreate(
      direction: values.direction,
      person: values.person,
      amount: values.amountText,
      currency: currency,
      startDate: values.startDate,
      dueDate: values.dueDate,
      note: values.note,
    );
  }

  /// Whether the debt can be saved: it is complete and, when changing one,
  /// something was edited.
  bool get canSave {
    return draft != null &&
        saveStatus != DebtFormSaveStatus.saving &&
        (!isEditing || isEdited);
  }

  DebtFormState copyWith({
    DebtFormStatus? status,
    DebtFormValues? values,
    DebtFormValues? baseline,
    Money? repaid,
    DateTime? lastRepaymentDate,
    int? version,
    Currency? currency,
    DebtFormSaveStatus? saveStatus,
    DebtRefusal? refusal,
    bool clearRefusal = false,
  }) {
    return DebtFormState(
      debtId: debtId,
      status: status ?? this.status,
      values: values ?? this.values,
      baseline: baseline ?? this.baseline,
      repaid: repaid ?? this.repaid,
      lastRepaymentDate: lastRepaymentDate ?? this.lastRepaymentDate,
      version: version ?? this.version,
      currency: currency ?? this.currency,
      saveStatus: saveStatus ?? this.saveStatus,
      refusal: clearRefusal ? null : refusal ?? this.refusal,
    );
  }

  @override
  List<Object?> get props => [
    debtId,
    status,
    values,
    baseline,
    repaid,
    lastRepaymentDate,
    version,
    currency,
    saveStatus,
    refusal,
  ];
}
