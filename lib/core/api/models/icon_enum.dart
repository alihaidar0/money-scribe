// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// * `gifts` - gifts.
/// * `health` - health.
/// * `entertainment` - entertainment.
/// * `shopping` - shopping.
/// * `education` - education.
/// * `travel` - travel.
/// * `subscriptions` - subscriptions.
/// * `other` - other.
@JsonEnum()
enum IconEnum {
  @JsonValue('gifts')
  gifts('gifts'),
  @JsonValue('health')
  health('health'),
  @JsonValue('entertainment')
  entertainment('entertainment'),
  @JsonValue('shopping')
  shopping('shopping'),
  @JsonValue('education')
  education('education'),
  @JsonValue('travel')
  travel('travel'),
  @JsonValue('subscriptions')
  subscriptions('subscriptions'),
  @JsonValue('other')
  other('other'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const IconEnum(this.json);

  factory IconEnum.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<IconEnum> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
