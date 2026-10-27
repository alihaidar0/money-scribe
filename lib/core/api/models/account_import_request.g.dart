// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_import_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountImportRequest _$AccountImportRequestFromJson(
  Map<String, dynamic> json,
) => AccountImportRequest(
  dataset: AccountImportDatasetEnum.fromJson(json['dataset'] as String),
  rows: (json['rows'] as List<dynamic>)
      .map((e) => AccountImportRowRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
  dryRun: json['dry_run'] as bool? ?? false,
);

Map<String, dynamic> _$AccountImportRequestToJson(
  AccountImportRequest instance,
) => <String, dynamic>{
  'dry_run': instance.dryRun,
  'dataset': _$AccountImportDatasetEnumEnumMap[instance.dataset]!,
  'rows': instance.rows,
};

const _$AccountImportDatasetEnumEnumMap = {
  AccountImportDatasetEnum.accounts: 'accounts',
  AccountImportDatasetEnum.$unknown: r'$unknown',
};
