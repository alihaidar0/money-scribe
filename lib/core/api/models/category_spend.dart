// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';

part 'category_spend.g.dart';

@JsonSerializable()
class CategorySpend {
  const CategorySpend({
    required this.categoryId,
    required this.categoryKey,
    required this.name,
    required this.icon,
    required this.amount,
  });

  factory CategorySpend.fromJson(Map<String, Object?> json) =>
      _$CategorySpendFromJson(json);

  @JsonKey(name: 'category_id')
  final String categoryId;

  /// The stable key of a built-in category; `null` for a custom one.
  @JsonKey(name: 'category_key')
  final String? categoryKey;

  /// A custom category's own name; for a built-in one the English fallback of its `key`.
  final String name;
  final String icon;

  /// Expense transactions of the category in the period.
  final Amount amount;

  Map<String, Object?> toJson() => _$CategorySpendToJson(this);
}
