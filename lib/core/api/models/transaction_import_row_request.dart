// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'currency_enum.dart';
import 'kind_enum.dart';

part 'transaction_import_row_request.g.dart';

/// A transaction of the file. Exactly one of `category_key` (a built-in category) and `category_name` (one of the.
/// person's own) names its category, and `account_name` an account that exists; none is created.
@JsonSerializable()
class TransactionImportRowRequest {
  const TransactionImportRowRequest({
    required this.row,
    required this.date,
    required this.kind,
    required this.amount,
    required this.currency,
    required this.accountName,
    this.note = '',
    this.categoryKey,
    this.categoryName,
  });

  factory TransactionImportRowRequest.fromJson(Map<String, Object?> json) =>
      _$TransactionImportRowRequestFromJson(json);

  /// The line in the file: a positive whole number, unique in the call.
  final int row;
  final DateTime date;
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
  @JsonKey(name: 'category_key')
  final String? categoryKey;
  @JsonKey(name: 'category_name')
  final String? categoryName;
  @JsonKey(name: 'account_name')
  final String accountName;
  final String note;

  Map<String, Object?> toJson() => _$TransactionImportRowRequestToJson(this);
}
