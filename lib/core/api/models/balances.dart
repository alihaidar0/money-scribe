// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'signed_amount.dart';

part 'balances.g.dart';

@JsonSerializable()
class Balances {
  const Balances({
    required this.first,
    required this.second,
    required this.month,
  });

  factory Balances.fromJson(Map<String, Object?> json) =>
      _$BalancesFromJson(json);

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final SignedAmount first;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final SignedAmount? second;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final SignedAmount month;

  Map<String, Object?> toJson() => _$BalancesToJson(this);
}
