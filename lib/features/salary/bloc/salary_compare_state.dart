part of 'salary_compare_bloc.dart';

enum SalaryCompareStatus {
  /// The saved months are being loaded.
  loading,

  /// The two months are compared.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class SalaryCompareState extends Equatable {
  const new({
    required this.left,
    required this.right,
    this.status = SalaryCompareStatus.loading,
    this.saved = const [],
    this.fixedItems = const {},
    this.scope = PeriodScope.month,
    this.monthsChosen = false,
  });

  final SalaryCompareStatus status;

  /// The month in the first column, the earlier one by default.
  final YearMonth left;

  /// The month in the second column, the later one by default.
  final YearMonth right;

  /// Every saved month, the newest first.
  final List<SalaryHistoryEntry> saved;

  /// The fixed items of the saved months that were loaded, by month. A month
  /// that is not here has none loaded yet, or has no saved salary.
  final Map<YearMonth, List<FixedItem>> fixedItems;

  /// What is compared; [effectiveScope] is what is shown.
  final PeriodScope scope;

  /// Whether [left] and [right] were chosen, by default from the saved months
  /// or by the user, so loading again keeps them.
  final bool monthsChosen;

  /// The saved salary of [month], or `null` when none was saved.
  SalaryHistoryEntry? entryOf(YearMonth month) {
    for (final entry in saved) {
      if (entry.month.month == month) return entry;
    }
    return null;
  }

  SalaryHistoryEntry? get leftEntry => entryOf(left);
  SalaryHistoryEntry? get rightEntry => entryOf(right);

  /// Whether the parts can be compared: either month is paid in two payments.
  bool get hasParts => SalaryComparison.hasParts(leftEntry, rightEntry);

  /// The scope that is shown: a part only while a month has parts.
  PeriodScope get effectiveScope => hasParts ? scope : PeriodScope.month;

  /// The lines of the comparison.
  List<ComparisonLine> get lines {
    return SalaryComparison.lines(
      leftEntry,
      rightEntry,
      effectiveScope,
      leftItems: fixedItems[left],
      rightItems: fixedItems[right],
    );
  }

  SalaryCompareState copyWith({
    SalaryCompareStatus? status,
    YearMonth? left,
    YearMonth? right,
    List<SalaryHistoryEntry>? saved,
    Map<YearMonth, List<FixedItem>>? fixedItems,
    PeriodScope? scope,
    bool? monthsChosen,
  }) {
    return SalaryCompareState(
      status: status ?? this.status,
      left: left ?? this.left,
      right: right ?? this.right,
      saved: saved ?? this.saved,
      fixedItems: fixedItems ?? this.fixedItems,
      scope: scope ?? this.scope,
      monthsChosen: monthsChosen ?? this.monthsChosen,
    );
  }

  @override
  List<Object> get props => [
    status,
    left,
    right,
    saved,
    fixedItems,
    scope,
    monthsChosen,
  ];
}
