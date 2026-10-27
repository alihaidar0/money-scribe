// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_month_import_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SalaryMonthImportRequest _$SalaryMonthImportRequestFromJson(
  Map<String, dynamic> json,
) => SalaryMonthImportRequest(
  dataset: SalaryMonthImportDatasetEnum.fromJson(json['dataset'] as String),
  rows: (json['rows'] as List<dynamic>)
      .map(
        (e) => SalaryMonthImportRowRequest.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  dryRun: json['dry_run'] as bool? ?? false,
);

Map<String, dynamic> _$SalaryMonthImportRequestToJson(
  SalaryMonthImportRequest instance,
) => <String, dynamic>{
  'dry_run': instance.dryRun,
  'dataset': _$SalaryMonthImportDatasetEnumEnumMap[instance.dataset]!,
  'rows': instance.rows,
};

const _$SalaryMonthImportDatasetEnumEnumMap = {
  SalaryMonthImportDatasetEnum.salaryMonths: 'salary_months',
  SalaryMonthImportDatasetEnum.$unknown: r'$unknown',
};
