// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'device_key.dart';

part 'device_key_list.g.dart';

/// The envelope of every list (ADR 0003). This list holds at most five keys, so it is one page.
@JsonSerializable()
class DeviceKeyList {
  const DeviceKeyList({
    required this.next,
    required this.previous,
    required this.results,
  });

  factory DeviceKeyList.fromJson(Map<String, Object?> json) =>
      _$DeviceKeyListFromJson(json);

  /// Always `null`: the list fits one page.
  final String? next;

  /// Always `null`: the list fits one page.
  final String? previous;
  final List<DeviceKey> results;

  Map<String, Object?> toJson() => _$DeviceKeyListToJson(this);
}
