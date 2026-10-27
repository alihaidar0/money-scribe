// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_import_row_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountImportRowRequest _$AccountImportRowRequestFromJson(
  Map<String, dynamic> json,
) => AccountImportRowRequest(
  row: (json['row'] as num).toInt(),
  name: json['name'] as String,
  kind: AccountKindEnum.fromJson(json['kind'] as String),
);

Map<String, dynamic> _$AccountImportRowRequestToJson(
  AccountImportRowRequest instance,
) => <String, dynamic>{
  'row': instance.row,
  'name': instance.name,
  'kind': _$AccountKindEnumEnumMap[instance.kind]!,
};

const _$AccountKindEnumEnumMap = {
  AccountKindEnum.card: 'card',
  AccountKindEnum.cash: 'cash',
  AccountKindEnum.other: 'other',
  AccountKindEnum.$unknown: r'$unknown',
};
