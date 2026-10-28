// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'amount.dart';
import 'kind_enum.dart';
import 'part_enum.dart';

part 'import_fixed_item_request.g.dart';

/// One fixed item in the `fixed_items` cell of a salary month. It has no currency: the month's.
@JsonSerializable()
class ImportFixedItemRequest {
  const ImportFixedItemRequest({
    required this.name,
    required this.amount,
    required this.kind,
    this.partValue,
    this.day,
  });

  factory ImportFixedItemRequest.fromJson(Map<String, Object?> json) =>
      _$ImportFixedItemRequestFromJson(json);

  final String name;

  /// A decimal string with exactly the number of digits of the currency, such as `12.50`.
  final Amount amount;
  final KindEnum kind;

  /// The name has been replaced because it contains a keyword. Original name: `part`.
  @JsonKey(name: 'part')
  final PartEnum? partValue;

  /// The day of the month, 1 to 31. Left out, or `null`, for none.
  final int? day;

  Map<String, Object?> toJson() => _$ImportFixedItemRequestToJson(this);
}
