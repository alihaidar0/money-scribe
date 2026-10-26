// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_request_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportRequestRequest _$ExportRequestRequestFromJson(
  Map<String, dynamic> json,
) => ExportRequestRequest(
  kinds: (json['kinds'] as List<dynamic>)
      .map((e) => DatasetEnum.fromJson(e as String))
      .toList(),
  currentPassword: json['current_password'] as String,
  from: json['from'] == null ? null : DateTime.parse(json['from'] as String),
  to: json['to'] == null ? null : DateTime.parse(json['to'] as String),
);

Map<String, dynamic> _$ExportRequestRequestToJson(
  ExportRequestRequest instance,
) => <String, dynamic>{
  'kinds': instance.kinds.map((e) => _$DatasetEnumEnumMap[e]!).toList(),
  'current_password': instance.currentPassword,
  'from': instance.from?.toIso8601String(),
  'to': instance.to?.toIso8601String(),
};

const _$DatasetEnumEnumMap = {
  DatasetEnum.transactions: 'transactions',
  DatasetEnum.debts: 'debts',
  DatasetEnum.salaryMonths: 'salary_months',
  DatasetEnum.$unknown: r'$unknown',
};
