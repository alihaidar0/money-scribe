// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'currency_enum.dart';
import 'kind_enum.dart';
import 'part_enum.dart';

part 'fixed_item.g.dart';

@JsonSerializable()
class FixedItem {
  const FixedItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.kind,
    required this.partValue,
    required this.day,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FixedItem.fromJson(Map<String, Object?> json) =>
      _$FixedItemFromJson(json);

  final String id;
  final String name;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount amount;

  /// The currency of the month.
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
  final KindEnum kind;

  /// The name has been replaced because it contains a keyword. Original name: `part`.
  /// The name has been replaced because it contains a keyword. Original name: `part`.
  /// The name has been replaced because it contains a keyword. Original name: `part`.
  @JsonKey(name: 'part')
  final PartEnum partValue;

  /// The day of the month, 1 to 31, or `null` when the item has none (an item saved without one).
  final int? day;
  final int version;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$FixedItemToJson(this);
}
