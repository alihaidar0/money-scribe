// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'platform_enum.dart';

part 'device_request.g.dart';

/// The label of the device, for the user's own "active sessions" screen (ADR 0009).
@JsonSerializable()
class DeviceRequest {
  const DeviceRequest({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
    this.osVersion = '',
  });

  factory DeviceRequest.fromJson(Map<String, Object?> json) =>
      _$DeviceRequestFromJson(json);

  /// A random UUID the app creates once at install and keeps in secure storage.
  @JsonKey(name: 'device_id')
  final String deviceId;

  /// A readable model name such as `Pixel 8`.
  @JsonKey(name: 'device_name')
  final String deviceName;
  final PlatformEnum platform;
  @JsonKey(name: 'os_version')
  final String osVersion;

  /// For example `1.0.0+1`.
  @JsonKey(name: 'app_version')
  final String appVersion;

  Map<String, Object?> toJson() => _$DeviceRequestToJson(this);
}
