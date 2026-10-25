// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'platform_enum.dart';

part 'device_key.g.dart';

@JsonSerializable()
class DeviceKey {
  const DeviceKey({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.attested,
    required this.isCurrent,
    required this.createdAt,
    required this.lastUsedAt,
    required this.expiresAt,
  });

  factory DeviceKey.fromJson(Map<String, Object?> json) =>
      _$DeviceKeyFromJson(json);

  final String id;
  @JsonKey(name: 'device_id')
  final String deviceId;
  @JsonKey(name: 'device_name')
  final String deviceName;
  final PlatformEnum platform;
  final bool attested;

  /// Whether this is the key of the device that made the request.
  @JsonKey(name: 'is_current')
  final bool isCurrent;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  Map<String, Object?> toJson() => _$DeviceKeyToJson(this);
}
