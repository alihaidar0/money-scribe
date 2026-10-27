// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_fixed_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportFixedItemRequest _$ImportFixedItemRequestFromJson(
  Map<String, dynamic> json,
) => ImportFixedItemRequest(
  name: json['name'] as String,
  amount: json['amount'] as Amount,
  kind: KindEnum.fromJson(json['kind'] as String),
  partValue: json['part'] == null
      ? null
      : PartEnum.fromJson(json['part'] as String),
);

Map<String, dynamic> _$ImportFixedItemRequestToJson(
  ImportFixedItemRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'amount': instance.amount,
  'kind': _$KindEnumEnumMap[instance.kind]!,
  'part': _$PartEnumEnumMap[instance.partValue],
};

const _$KindEnumEnumMap = {
  KindEnum.income: 'income',
  KindEnum.expense: 'expense',
  KindEnum.$unknown: r'$unknown',
};

const _$PartEnumEnumMap = {
  PartEnum.first: 'first',
  PartEnum.second: 'second',
  PartEnum.$unknown: r'$unknown',
};
