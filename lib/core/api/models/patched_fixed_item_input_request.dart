// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'currency_enum.dart';
import 'kind_enum.dart';
import 'part_enum.dart';

part 'patched_fixed_item_input_request.g.dart';

/// A fixed item to add or to change. It has no currency of its own: the month's.
@JsonSerializable()
class PatchedFixedItemInputRequest {
  const PatchedFixedItemInputRequest({
    required this.name,
    required this.amount,
    required this.kind,
    required this.day,
    required this.currency,
    this.partValue = PartEnum.first,
  });

  factory PatchedFixedItemInputRequest.fromJson(Map<String, Object?> json) =>
      _$PatchedFixedItemInputRequestFromJson(json);

  /// 1 to 50 characters, trimmed.
  final String name;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount amount;
  final KindEnum kind;

  /// The name has been replaced because it contains a keyword. Original name: `part`.
  /// The name has been replaced because it contains a keyword. Original name: `part`.
  /// The name has been replaced because it contains a keyword. Original name: `part`.
  @JsonKey(name: 'part')
  final PartEnum partValue;

  /// The day of the month the item falls on, 1 to 31, or `null` for none. A day past the end of the month (31 in September) counts as its last day; it is stored and returned as sent. It does not change `part`, which is still the one sent.
  final int? day;

  /// May be left out. If it is sent it must be the currency of the month.
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

  Map<String, Object?> toJson() => _$PatchedFixedItemInputRequestToJson(this);
}
