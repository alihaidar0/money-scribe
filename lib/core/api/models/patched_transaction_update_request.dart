// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'kind_enum.dart';

part 'patched_transaction_update_request.g.dart';

/// A change to a transaction: the fields of the create except `currency`, which is `400 read_only`.
@JsonSerializable()
class PatchedTransactionUpdateRequest {
  const PatchedTransactionUpdateRequest({
    required this.kind,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.accountId,
    required this.note,
  });

  factory PatchedTransactionUpdateRequest.fromJson(Map<String, Object?> json) =>
      _$PatchedTransactionUpdateRequestFromJson(json);

  final KindEnum kind;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount amount;

  /// A calendar day, 2000-01-01 to 2099-12-31.
  final DateTime date;
  @JsonKey(name: 'category_id')
  final String categoryId;
  @JsonKey(name: 'account_id')
  final String accountId;

  /// 0 to 100 characters, trimmed.
  final String note;

  Map<String, Object?> toJson() =>
      _$PatchedTransactionUpdateRequestToJson(this);
}
