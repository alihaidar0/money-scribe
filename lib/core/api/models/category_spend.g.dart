// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_spend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategorySpend _$CategorySpendFromJson(Map<String, dynamic> json) =>
    CategorySpend(
      categoryId: json['category_id'] as String,
      categoryKey: json['category_key'] as String?,
      name: json['name'] as String,
      icon: json['icon'] as String,
      amount: json['amount'] as Amount,
    );

Map<String, dynamic> _$CategorySpendToJson(CategorySpend instance) =>
    <String, dynamic>{
      'category_id': instance.categoryId,
      'category_key': instance.categoryKey,
      'name': instance.name,
      'icon': instance.icon,
      'amount': instance.amount,
    };
