// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'debt_direction_enum.dart';
import 'debt_status_enum.dart';

part 'debt_line.g.dart';

@JsonSerializable()
class DebtLine {
  const DebtLine({
    required this.id,
    required this.person,
    required this.direction,
    required this.remaining,
    required this.status,
    required this.dueDate,
  });

  factory DebtLine.fromJson(Map<String, Object?> json) =>
      _$DebtLineFromJson(json);

  final String id;
  final String person;
  final DebtDirectionEnum direction;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount remaining;
  final DebtStatusEnum status;
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;

  Map<String, Object?> toJson() => _$DebtLineToJson(this);
}
