part of 'transaction_form_bloc.dart';

enum TransactionFormStatus {
  /// What the form offers is being loaded.
  loading,

  /// The form can be filled in.
  ready,

  /// The transaction to change does not exist.
  notFound,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

enum TransactionFormSaveStatus {
  /// Nothing to report: not saved yet, or edited since.
  idle,

  /// The transaction is being sent to the server.
  saving,

  /// The transaction was saved.
  saved,

  /// The transaction could not be saved; what was typed is kept.
  failed,

  /// The server did not accept the transaction for a reason the person can act
  /// on; [TransactionFormState.refusal] says which. What was typed is kept.
  refused,

  /// The transaction was changed on another device first. Nothing was saved,
  /// and the form is loaded again with what is on the server.
  stale,
}

enum TransactionFormDeleteStatus {
  /// Nothing to report.
  idle,

  /// The transaction is being deleted on the server.
  deleting,

  /// The transaction was deleted.
  deleted,

  /// The transaction could not be deleted; it is still there.
  failed,

  /// The transaction was changed on another device first. Nothing was
  /// deleted, and the form is loaded again with what is on the server.
  stale,
}

/// What can be typed into the form.
final class TransactionFormValues extends Equatable {
  const new({
    required this.date,
    this.kind = TransactionKind.expense,
    this.amountText = '',
    this.categoryId,
    this.accountId,
    this.note = '',
  });

  final TransactionKind kind;

  /// The amount as typed, such as `1284.50`.
  final String amountText;
  final DateTime date;
  final String? categoryId;
  final String? accountId;
  final String note;

  TransactionFormValues copyWith({
    TransactionKind? kind,
    String? amountText,
    DateTime? date,
    String? categoryId,
    bool clearCategory = false,
    String? accountId,
    bool clearAccount = false,
    String? note,
  }) {
    return TransactionFormValues(
      kind: kind ?? this.kind,
      amountText: amountText ?? this.amountText,
      date: date ?? this.date,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      accountId: clearAccount ? null : accountId ?? this.accountId,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
    kind,
    amountText,
    date,
    categoryId,
    accountId,
    note,
  ];
}

final class TransactionFormState extends Equatable {
  const new({
    required this.values,
    required this.baseline,
    this.transactionId,
    this.status = TransactionFormStatus.loading,
    this.accounts = const [],
    this.categories = const [],
    this.cycle = const PayCycle.onePayment(),
    this.currency = Currency.rub,
    this.version,
    this.refusal,
    this.saveStatus = TransactionFormSaveStatus.idle,
    this.deleteStatus = TransactionFormDeleteStatus.idle,
  });

  final TransactionFormStatus status;

  /// The id of the transaction being changed, or `null` for a new one.
  final String? transactionId;

  final TransactionFormValues values;

  /// What the form held when it was loaded, to tell whether it was edited.
  final TransactionFormValues baseline;

  final List<Account> accounts;
  final List<TransactionCategory> categories;

  /// How the salary is paid and on which days, so the day shows its part.
  final PayCycle cycle;

  /// Whether the salary is paid in two payments.
  bool get twoPayments => cycle.hasParts;

  /// The currency of the amount: the one the transaction was made in when
  /// changing one, which cannot be changed.
  final Currency currency;

  /// The version of the transaction being changed, as the server holds it, or
  /// `null` for a new one.
  final int? version;

  /// Why the server refused the last save, while [saveStatus] says so.
  final TransactionRefusal? refusal;

  final TransactionFormSaveStatus saveStatus;
  final TransactionFormDeleteStatus deleteStatus;

  /// Whether an existing transaction is being changed.
  bool get isEditing => transactionId != null;

  /// Whether the form differs from what was loaded.
  bool get isEdited => values != baseline;

  /// The categories that fit the chosen Expense or Income.
  List<TransactionCategory> get availableCategories {
    return [
      for (final category in categories)
        if (category.isFor(values.kind)) category,
    ];
  }

  /// The chosen account, or `null`.
  Account? get account {
    for (final account in accounts) {
      if (account.id == values.accountId) return account;
    }
    return null;
  }

  /// What was typed as a transaction, or `null` while it is incomplete.
  TransactionDraft? get draft {
    return TransactionDraft.tryCreate(
      amount: values.amountText,
      currency: currency,
      kind: values.kind,
      date: values.date,
      categoryId: values.categoryId,
      accountId: values.accountId,
      note: values.note,
    );
  }

  /// Whether the transaction can be saved: it is complete and, when changing
  /// one, something was edited.
  bool get canSave {
    return draft != null &&
        saveStatus != TransactionFormSaveStatus.saving &&
        (!isEditing || isEdited);
  }

  TransactionFormState copyWith({
    TransactionFormStatus? status,
    String? transactionId,
    TransactionFormValues? values,
    TransactionFormValues? baseline,
    List<Account>? accounts,
    List<TransactionCategory>? categories,
    PayCycle? cycle,
    Currency? currency,
    int? version,
    TransactionRefusal? refusal,
    TransactionFormSaveStatus? saveStatus,
    TransactionFormDeleteStatus? deleteStatus,
  }) {
    return TransactionFormState(
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      values: values ?? this.values,
      baseline: baseline ?? this.baseline,
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      cycle: cycle ?? this.cycle,
      currency: currency ?? this.currency,
      version: version ?? this.version,
      refusal: refusal ?? this.refusal,
      saveStatus: saveStatus ?? this.saveStatus,
      deleteStatus: deleteStatus ?? this.deleteStatus,
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactionId,
    values,
    baseline,
    accounts,
    categories,
    cycle,
    currency,
    version,
    refusal,
    saveStatus,
    deleteStatus,
  ];
}
