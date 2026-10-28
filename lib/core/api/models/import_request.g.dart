// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ImportRequestToJson(ImportRequest instance) =>
    <String, dynamic>{};

ImportRequestAccountImportRequest _$ImportRequestAccountImportRequestFromJson(
  Map<String, dynamic> json,
) => ImportRequestAccountImportRequest(
  dryRun: json['dryRun'] as bool,
  dataset: AccountImportDatasetEnum.fromJson(json['dataset'] as String),
  rows: (json['rows'] as List<dynamic>)
      .map((e) => AccountImportRowRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ImportRequestAccountImportRequestToJson(
  ImportRequestAccountImportRequest instance,
) => <String, dynamic>{
  'dryRun': instance.dryRun,
  'dataset': _$AccountImportDatasetEnumEnumMap[instance.dataset]!,
  'rows': instance.rows,
};

const _$AccountImportDatasetEnumEnumMap = {
  AccountImportDatasetEnum.accounts: 'accounts',
  AccountImportDatasetEnum.$unknown: r'$unknown',
};

ImportRequestCategoryImportRequest _$ImportRequestCategoryImportRequestFromJson(
  Map<String, dynamic> json,
) => ImportRequestCategoryImportRequest(
  dryRun: json['dryRun'] as bool,
  dataset: CategoryImportDatasetEnum.fromJson(json['dataset'] as String),
  rows: (json['rows'] as List<dynamic>)
      .map((e) => CategoryImportRowRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ImportRequestCategoryImportRequestToJson(
  ImportRequestCategoryImportRequest instance,
) => <String, dynamic>{
  'dryRun': instance.dryRun,
  'dataset': _$CategoryImportDatasetEnumEnumMap[instance.dataset]!,
  'rows': instance.rows,
};

const _$CategoryImportDatasetEnumEnumMap = {
  CategoryImportDatasetEnum.categories: 'categories',
  CategoryImportDatasetEnum.$unknown: r'$unknown',
};

ImportRequestTransactionImportRequest
_$ImportRequestTransactionImportRequestFromJson(Map<String, dynamic> json) =>
    ImportRequestTransactionImportRequest(
      dryRun: json['dryRun'] as bool,
      dataset: TransactionImportDatasetEnum.fromJson(json['dataset'] as String),
      rows: (json['rows'] as List<dynamic>)
          .map(
            (e) =>
                TransactionImportRowRequest.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$ImportRequestTransactionImportRequestToJson(
  ImportRequestTransactionImportRequest instance,
) => <String, dynamic>{
  'dryRun': instance.dryRun,
  'dataset': _$TransactionImportDatasetEnumEnumMap[instance.dataset]!,
  'rows': instance.rows,
};

const _$TransactionImportDatasetEnumEnumMap = {
  TransactionImportDatasetEnum.transactions: 'transactions',
  TransactionImportDatasetEnum.$unknown: r'$unknown',
};

ImportRequestDebtImportRequest _$ImportRequestDebtImportRequestFromJson(
  Map<String, dynamic> json,
) => ImportRequestDebtImportRequest(
  dryRun: json['dryRun'] as bool,
  dataset: DebtImportDatasetEnum.fromJson(json['dataset'] as String),
  rows: (json['rows'] as List<dynamic>)
      .map((e) => DebtImportRowRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ImportRequestDebtImportRequestToJson(
  ImportRequestDebtImportRequest instance,
) => <String, dynamic>{
  'dryRun': instance.dryRun,
  'dataset': _$DebtImportDatasetEnumEnumMap[instance.dataset]!,
  'rows': instance.rows,
};

const _$DebtImportDatasetEnumEnumMap = {
  DebtImportDatasetEnum.debts: 'debts',
  DebtImportDatasetEnum.$unknown: r'$unknown',
};

ImportRequestSalaryMonthImportRequest
_$ImportRequestSalaryMonthImportRequestFromJson(Map<String, dynamic> json) =>
    ImportRequestSalaryMonthImportRequest(
      dryRun: json['dryRun'] as bool,
      dataset: SalaryMonthImportDatasetEnum.fromJson(json['dataset'] as String),
      rows: (json['rows'] as List<dynamic>)
          .map(
            (e) =>
                SalaryMonthImportRowRequest.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$ImportRequestSalaryMonthImportRequestToJson(
  ImportRequestSalaryMonthImportRequest instance,
) => <String, dynamic>{
  'dryRun': instance.dryRun,
  'dataset': _$SalaryMonthImportDatasetEnumEnumMap[instance.dataset]!,
  'rows': instance.rows,
};

const _$SalaryMonthImportDatasetEnumEnumMap = {
  SalaryMonthImportDatasetEnum.salaryMonths: 'salary_months',
  SalaryMonthImportDatasetEnum.$unknown: r'$unknown',
};
