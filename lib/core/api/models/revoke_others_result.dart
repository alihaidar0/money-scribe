// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'revoke_others_result.g.dart';

@JsonSerializable()
class RevokeOthersResult {
  const RevokeOthersResult({
    required this.ended,
    required this.deviceKeysRemoved,
  });

  factory RevokeOthersResult.fromJson(Map<String, Object?> json) =>
      _$RevokeOthersResultFromJson(json);

  /// The sessions this call ended.
  final int ended;

  /// The fingerprint keys removed: every key but the current device's, signed-out phones included.
  @JsonKey(name: 'device_keys_removed')
  final int deviceKeysRemoved;

  Map<String, Object?> toJson() => _$RevokeOthersResultToJson(this);
}
