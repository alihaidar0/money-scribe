// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum DatasetEnum {
  @JsonValue('accounts')
  accounts('accounts'),
  @JsonValue('categories')
  categories('categories'),
  @JsonValue('transactions')
  transactions('transactions'),
  @JsonValue('debts')
  debts('debts'),
  @JsonValue('salary_months')
  salaryMonths('salary_months'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const DatasetEnum(this.json);

  factory DatasetEnum.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<DatasetEnum> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
