import 'package:equatable/equatable.dart';

/// A calendar month, such as October 2026. Months are what the salary, the
/// overview and the reports are kept by.
final class YearMonth extends Equatable implements Comparable<YearMonth> {
  const new(this.year, this.month)
    : assert(month >= 1 && month <= 12, 'A month is 1 to 12');

  /// The month [date] is in.
  new fromDate(DateTime date) : this(date.year, date.month);

  final int year;

  /// 1 for January to 12 for December.
  final int month;

  YearMonth get next {
    return month == 12 ? YearMonth(year + 1, 1) : YearMonth(year, month + 1);
  }

  YearMonth get previous {
    return month == 1 ? YearMonth(year - 1, 12) : YearMonth(year, month - 1);
  }

  /// The first day of the month, at midnight.
  DateTime get firstDay => DateTime(year, month);

  /// The month as text for an address, such as `2026-09`. [tryParse] reads it
  /// back.
  String get param {
    final paddedYear = year.toString().padLeft(4, '0');
    final paddedMonth = month.toString().padLeft(2, '0');
    return '$paddedYear-$paddedMonth';
  }

  /// Reads a month written the way [param] writes it, or `null` for anything
  /// else.
  static YearMonth? tryParse(String? text) {
    final match = _param.firstMatch(text ?? '');
    if (match == null) return null;
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return null;
    return YearMonth(int.parse(match.group(1)!), month);
  }

  static final RegExp _param = RegExp(r'^(\d{4})-(\d{2})$');

  @override
  int compareTo(YearMonth other) {
    return year != other.year ? year - other.year : month - other.month;
  }

  bool operator <(YearMonth other) => compareTo(other) < 0;
  bool operator >(YearMonth other) => compareTo(other) > 0;
  bool operator <=(YearMonth other) => compareTo(other) <= 0;
  bool operator >=(YearMonth other) => compareTo(other) >= 0;

  @override
  List<Object> get props => [year, month];

  @override
  String toString() => 'YearMonth($year-${month.toString().padLeft(2, '0')})';
}
