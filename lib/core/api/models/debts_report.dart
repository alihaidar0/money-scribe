// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency_debts.dart';

part 'debts_report.g.dart';

@JsonSerializable()
class DebtsReport {
  const DebtsReport({required this.hasData, required this.byCurrency});

  factory DebtsReport.fromJson(Map<String, Object?> json) =>
      _$DebtsReportFromJson(json);

  /// True when the person has any debt, settled or not: it tells "no debts at all" from "all settled".
  @JsonKey(name: 'has_data')
  final bool hasData;

  /// One block per currency that has unsettled debts, ordered by currency code.
  @JsonKey(name: 'by_currency')
  final List<CurrencyDebts> byCurrency;

  Map<String, Object?> toJson() => _$DebtsReportToJson(this);
}
