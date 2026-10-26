// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_input_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountInputRequest _$AccountInputRequestFromJson(Map<String, dynamic> json) =>
    AccountInputRequest(
      name: json['name'] as String,
      kind: AccountKindEnum.fromJson(json['kind'] as String),
    );

Map<String, dynamic> _$AccountInputRequestToJson(
  AccountInputRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'kind': _$AccountKindEnumEnumMap[instance.kind]!,
};

const _$AccountKindEnumEnumMap = {
  AccountKindEnum.card: 'card',
  AccountKindEnum.cash: 'cash',
  AccountKindEnum.other: 'other',
  AccountKindEnum.$unknown: r'$unknown',
};
