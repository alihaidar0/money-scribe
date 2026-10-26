// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'category_spend.dart';

part 'report_slice.g.dart';

@JsonSerializable()
class ReportSlice {
  const ReportSlice({
    required this.incomeTransactions,
    required this.purchases,
    required this.categories,
  });

  factory ReportSlice.fromJson(Map<String, Object?> json) =>
      _$ReportSliceFromJson(json);

  /// Income transactions dated in the period. The salary and the recurring income are not included.
  @JsonKey(name: 'income_transactions')
  final Amount incomeTransactions;

  /// Expense transactions dated in the period. The fixed costs are not included.
  final Amount purchases;

  /// The spending by category (expense transactions only), the biggest `amount` first, ties by `category_id`; the amounts add up to `purchases`.
  final List<CategorySpend> categories;

  Map<String, Object?> toJson() => _$ReportSliceToJson(this);
}
