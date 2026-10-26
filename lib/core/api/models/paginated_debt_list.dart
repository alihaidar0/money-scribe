// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'debt.dart';

part 'paginated_debt_list.g.dart';

@JsonSerializable()
class PaginatedDebtList {
  const PaginatedDebtList({
    required this.next,
    required this.previous,
    required this.results,
  });

  factory PaginatedDebtList.fromJson(Map<String, Object?> json) =>
      _$PaginatedDebtListFromJson(json);

  /// The URL of the next page, or `null` on the last one. Follow it as it is.
  final String? next;

  /// The URL of the previous page, or `null` on the first one.
  final String? previous;
  final List<Debt> results;

  Map<String, Object?> toJson() => _$PaginatedDebtListToJson(this);
}
