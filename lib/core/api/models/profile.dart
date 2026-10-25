// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'language_enum.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.language,
    required this.timeZone,
  });

  factory Profile.fromJson(Map<String, Object?> json) =>
      _$ProfileFromJson(json);

  final String id;
  final String name;
  final String email;
  final LanguageEnum language;
  @JsonKey(name: 'time_zone')
  final String timeZone;

  Map<String, Object?> toJson() => _$ProfileToJson(this);
}
