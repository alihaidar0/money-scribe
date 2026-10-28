// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// * `expense` - Expense.
/// * `income` - Income.
/// * `both` - Both.
@JsonEnum()
enum CategoryKindEnum {
  @JsonValue('expense')
  expense('expense'),
  @JsonValue('income')
  income('income'),
  @JsonValue('both')
  both('both'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const CategoryKindEnum(this.json);

  factory CategoryKindEnum.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<CategoryKindEnum> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
