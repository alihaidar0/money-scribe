// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';

part 'repayment.g.dart';

@JsonSerializable()
class Repayment {
  const Repayment({
    required this.id,
    required this.amount,
    required this.date,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Repayment.fromJson(Map<String, Object?> json) =>
      _$RepaymentFromJson(json);

  final String id;

  /// In the currency of the debt.
  final Amount amount;
  final DateTime date;

  /// The `If-Match` of a change or a delete of this repayment (not the `ETag` of an answer).
  final int version;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$RepaymentToJson(this);
}
