// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'currency_enum.dart';
import 'kind_enum.dart';

part 'transaction.g.dart';

@JsonSerializable()
class Transaction {
  const Transaction({
    required this.id,
    required this.kind,
    required this.amount,
    required this.currency,
    required this.date,
    required this.categoryId,
    required this.accountId,
    required this.note,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, Object?> json) =>
      _$TransactionFromJson(json);

  final String id;
  final KindEnum kind;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount amount;

  /// The ISO 4217 code of the currency.
  ///
  /// * `RUB` - RUB.
  /// * `USD` - USD.
  /// * `EUR` - EUR.
  /// * `GBP` - GBP.
  /// * `TRY` - TRY.
  /// * `SAR` - SAR.
  /// * `AED` - AED.
  /// * `EGP` - EGP.
  /// * `JPY` - JPY.
  /// * `KWD` - KWD.
  final CurrencyEnum currency;
  final DateTime date;
  @JsonKey(name: 'category_id')
  final String categoryId;
  @JsonKey(name: 'account_id')
  final String accountId;
  final String note;
  final int version;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$TransactionToJson(this);
}
