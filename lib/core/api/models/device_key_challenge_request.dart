// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'device_key_challenge_request.g.dart';

@JsonSerializable()
class DeviceKeyChallengeRequest {
  const DeviceKeyChallengeRequest({required this.deviceId});

  factory DeviceKeyChallengeRequest.fromJson(Map<String, Object?> json) =>
      _$DeviceKeyChallengeRequestFromJson(json);

  /// The `device_id` of the app install (the same random id as in the `device` object).
  @JsonKey(name: 'device_id')
  final String deviceId;

  Map<String, Object?> toJson() => _$DeviceKeyChallengeRequestToJson(this);
}
