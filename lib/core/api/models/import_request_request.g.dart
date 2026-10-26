// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_request_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportRequestRequest _$ImportRequestRequestFromJson(
  Map<String, dynamic> json,
) => ImportRequestRequest(
  dataset: DatasetEnum.fromJson(json['dataset'] as String),
  rows: (json['rows'] as List<dynamic>)
      .map((e) => Rows.fromJson(e as Map<String, dynamic>))
      .toList(),
  dryRun: json['dry_run'] as bool? ?? false,
);

Map<String, dynamic> _$ImportRequestRequestToJson(
  ImportRequestRequest instance,
) => <String, dynamic>{
  'dataset': _$DatasetEnumEnumMap[instance.dataset]!,
  'dry_run': instance.dryRun,
  'rows': instance.rows,
};

const _$DatasetEnumEnumMap = {
  DatasetEnum.transactions: 'transactions',
  DatasetEnum.debts: 'debts',
  DatasetEnum.salaryMonths: 'salary_months',
  DatasetEnum.$unknown: r'$unknown',
};
