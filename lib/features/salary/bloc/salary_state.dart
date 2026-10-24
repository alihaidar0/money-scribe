part of 'salary_bloc.dart';

enum SalaryStatus {
  /// The month is being loaded.
  loading,

  /// The month is shown and can be edited.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

enum SalarySaveStatus {
  /// Nothing to report: not saved yet, or edited since.
  idle,

  /// The month is being sent to the server.
  saving,

  /// The month was saved.
  saved,

  /// The month could not be saved; what was typed is kept.
  failed,

  /// The month was changed on another device since it was loaded, so nothing
  /// was saved; what was typed is kept and the person chooses whether to load
  /// the latest version.
  stale,
}

enum SalaryDeleteStatus {
  /// Nothing to report.
  idle,

  /// The month is being deleted on the server.
  deleting,

  /// The month was deleted.
  deleted,

  /// The month could not be deleted; it is still saved.
  failed,

  /// The month was changed on another device since it was loaded, so nothing
  /// was deleted.
  stale,
}

final class SalaryState extends Equatable {
  const new({
    required this.month,
    this.status = SalaryStatus.loading,
    this.form = const SalaryForm(),
    this.baseline = const SalaryForm(),
    this.isSaved = false,
    this.version = 0,
    this.saveStatus = SalarySaveStatus.idle,
    this.deleteStatus = SalaryDeleteStatus.idle,
    this.formVersion = 0,
  });

  final SalaryStatus status;

  /// The month shown, or being loaded.
  final YearMonth month;

  /// What is typed now.
  final SalaryForm form;

  /// What the form held when the month was loaded or last saved, to tell
  /// whether it was edited.
  final SalaryForm baseline;

  /// Whether this month exists on the server, as opposed to a new, empty one.
  final bool isSaved;

  /// The server's version of the saved month; `0` while [isSaved] is false.
  final int version;

  final SalarySaveStatus saveStatus;

  final SalaryDeleteStatus deleteStatus;

  /// Changes whenever the form is replaced as a whole (a month was loaded), so
  /// the screen starts its text fields again from [form]. Typing does not
  /// change it.
  final int formVersion;

  /// The calculation of the form, or `null` while a required number is
  /// missing.
  SalaryCalculation? get calculation {
    final inputs = form.inputs;
    return inputs == null ? null : SalaryCalculator.calculate(inputs);
  }

  /// The calculated lines, or `null` while the form cannot be calculated.
  SalaryResult? get result {
    return switch (calculation) {
      SalaryComputed(:final result) => result,
      _ => null,
    };
  }

  /// Whether the month can be saved.
  bool get canSave => result != null && saveStatus != SalarySaveStatus.saving;

  /// Whether the form differs from what was loaded or last saved.
  bool get isEdited => form != baseline;

  SalaryState copyWith({
    SalaryStatus? status,
    YearMonth? month,
    SalaryForm? form,
    SalaryForm? baseline,
    bool? isSaved,
    int? version,
    SalarySaveStatus? saveStatus,
    SalaryDeleteStatus? deleteStatus,
    int? formVersion,
  }) {
    return SalaryState(
      status: status ?? this.status,
      month: month ?? this.month,
      form: form ?? this.form,
      baseline: baseline ?? this.baseline,
      isSaved: isSaved ?? this.isSaved,
      version: version ?? this.version,
      saveStatus: saveStatus ?? this.saveStatus,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      formVersion: formVersion ?? this.formVersion,
    );
  }

  @override
  List<Object> get props => [
    status,
    month,
    form,
    baseline,
    isSaved,
    version,
    saveStatus,
    deleteStatus,
    formVersion,
  ];
}
