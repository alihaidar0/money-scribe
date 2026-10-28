// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'currency_enum.dart';
import 'kind_enum.dart';
import 'part_enum.dart';

part 'transaction_create_request.g.dart';

/// A transaction to add. Anything else (`id`, `version`, ...) is `400 read_only`.
@JsonSerializable()
class TransactionCreateRequest {
  const TransactionCreateRequest({
    required this.kind,
    required this.amount,
    required this.currency,
    required this.date,
    required this.categoryId,
    required this.accountId,
    this.note = '',
    this.partValue,
    this.partMonth,
  });

  factory TransactionCreateRequest.fromJson(Map<String, Object?> json) =>
      _$TransactionCreateRequestFromJson(json);

  /// The name has been replaced because it contains a keyword. Original name: `part`.
  /// The name has been replaced because it contains a keyword. Original name: `part`.
  /// The name has been replaced because it contains a keyword. Original name: `part`.
  @JsonKey(name: 'part')
  final PartEnum? partValue;

  /// The month the `part` belongs to, `YYYY-MM` (2000-01 to 2099-12).
  @JsonKey(name: 'part_month')
  final String? partMonth;
  final KindEnum kind;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount amount;

  /// Of the record, and fixed for good: it cannot be changed afterwards.
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

  /// A calendar day, 2000-01-01 to 2099-12-31.
  final DateTime date;

  /// A built-in category or one of the person's own, and one that allows the `kind`.
  @JsonKey(name: 'category_id')
  final String categoryId;

  /// One of the person's accounts.
  @JsonKey(name: 'account_id')
  final String accountId;

  /// 0 to 100 characters, trimmed.
  final String note;

  Map<String, Object?> toJson() => _$TransactionCreateRequestToJson(this);
}
