// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'patched_profile_update_request.g.dart';

/// Only the name can be edited here; any other field is refused instead of silently ignored.
@JsonSerializable()
class PatchedProfileUpdateRequest {
  const PatchedProfileUpdateRequest({this.name});

  factory PatchedProfileUpdateRequest.fromJson(Map<String, Object?> json) =>
      _$PatchedProfileUpdateRequestFromJson(json);

  /// The display name, 1 to 100 characters, trimmed.
  final String? name;

  Map<String, Object?> toJson() => _$PatchedProfileUpdateRequestToJson(this);
}
