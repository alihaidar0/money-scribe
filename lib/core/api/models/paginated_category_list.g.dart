// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_category_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedCategoryList _$PaginatedCategoryListFromJson(
  Map<String, dynamic> json,
) => PaginatedCategoryList(
  next: json['next'] as String?,
  previous: json['previous'] as String?,
  results: (json['results'] as List<dynamic>)
      .map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PaginatedCategoryListToJson(
  PaginatedCategoryList instance,
) => <String, dynamic>{
  'next': instance.next,
  'previous': instance.previous,
  'results': instance.results,
};
