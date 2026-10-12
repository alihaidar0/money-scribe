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
}

final class SalaryState extends Equatable {
  const new({
    required this.month,
    this.status = SalaryStatus.loading,
    this.form = const SalaryForm(),
    this.baseline = const SalaryForm(),
    this.isSaved = false,
    this.saveStatus = SalarySaveStatus.idle,
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

  final SalarySaveStatus saveStatus;

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
    SalarySaveStatus? saveStatus,
    int? formVersion,
  }) {
    return SalaryState(
      status: status ?? this.status,
      month: month ?? this.month,
      form: form ?? this.form,
      baseline: baseline ?? this.baseline,
      isSaved: isSaved ?? this.isSaved,
      saveStatus: saveStatus ?? this.saveStatus,
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
    saveStatus,
    formVersion,
  ];
}
