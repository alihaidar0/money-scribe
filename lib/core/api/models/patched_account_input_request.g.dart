// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patched_account_input_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchedAccountInputRequest _$PatchedAccountInputRequestFromJson(
  Map<String, dynamic> json,
) => PatchedAccountInputRequest(
  name: json['name'] as String?,
  kind: json['kind'] == null
      ? null
      : AccountKindEnum.fromJson(json['kind'] as String),
);

Map<String, dynamic> _$PatchedAccountInputRequestToJson(
  PatchedAccountInputRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'kind': _$AccountKindEnumEnumMap[instance.kind],
};

const _$AccountKindEnumEnumMap = {
  AccountKindEnum.card: 'card',
  AccountKindEnum.cash: 'cash',
  AccountKindEnum.other: 'other',
  AccountKindEnum.$unknown: r'$unknown',
};
