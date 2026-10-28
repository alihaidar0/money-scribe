// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportResult _$ImportResultFromJson(Map<String, dynamic> json) => ImportResult(
  dataset: DatasetEnum.fromJson(json['dataset'] as String),
  dryRun: json['dry_run'] as bool,
  imported: (json['imported'] as num).toInt(),
  skipped: (json['skipped'] as num).toInt(),
  problems: (json['problems'] as List<dynamic>)
      .map((e) => ImportProblem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ImportResultToJson(ImportResult instance) =>
    <String, dynamic>{
      'dataset': _$DatasetEnumEnumMap[instance.dataset]!,
      'dry_run': instance.dryRun,
      'imported': instance.imported,
      'skipped': instance.skipped,
      'problems': instance.problems,
    };

const _$DatasetEnumEnumMap = {
  DatasetEnum.accounts: 'accounts',
  DatasetEnum.categories: 'categories',
  DatasetEnum.transactions: 'transactions',
  DatasetEnum.debts: 'debts',
  DatasetEnum.salaryMonths: 'salary_months',
  DatasetEnum.$unknown: r'$unknown',
};
