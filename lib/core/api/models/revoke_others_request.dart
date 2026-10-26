// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'revoke_others_request.g.dart';

/// A field that the serializer does not have is ``400 read_only`` on that field, never silently ignored.
///
/// For the edit of a record that has fields the client may not set (a version, a result, an id): a client that.
/// sends one learns at once that it was not applied.
@JsonSerializable()
class RevokeOthersRequest {
  const RevokeOthersRequest({required this.currentPassword});

  factory RevokeOthersRequest.fromJson(Map<String, Object?> json) =>
      _$RevokeOthersRequestFromJson(json);

  /// The account password, to confirm.
  @JsonKey(name: 'current_password')
  final String currentPassword;

  Map<String, Object?> toJson() => _$RevokeOthersRequestToJson(this);
}
