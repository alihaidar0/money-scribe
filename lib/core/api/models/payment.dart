// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'part_enum.dart';

part 'payment.g.dart';

@JsonSerializable()
class Payment {
  const Payment({required this.partValue, required this.amount});

  factory Payment.fromJson(Map<String, Object?> json) =>
      _$PaymentFromJson(json);

  /// The name has been replaced because it contains a keyword. Original name: `part`.
  /// The name has been replaced because it contains a keyword. Original name: `part`.
  /// The name has been replaced because it contains a keyword. Original name: `part`.
  @JsonKey(name: 'part')
  final PartEnum partValue;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount amount;

  Map<String, Object?> toJson() => _$PaymentToJson(this);
}
