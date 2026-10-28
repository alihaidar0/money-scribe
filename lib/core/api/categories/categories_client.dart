// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/category.dart';
import '../models/category_input_request.dart';
import '../models/paginated_category_list.dart';
import '../models/patched_category_input_request.dart';

part 'categories_client.g.dart';

@RestApi()
abstract class CategoriesClient {
  factory CategoriesClient(Dio dio, {String? baseUrl}) = _CategoriesClient;

  /// The categories a person can use.
  ///
  /// The seven built-in categories first, in a fixed order, then the person's own in the order they were made. Cursor pagination (`limit`, `cursor`; follow `next`): ask `limit=100` to get the whole list in one call.
  ///
  /// [cursor] - An opaque position taken from `next` or `previous`; never built by the client.
  ///
  /// [limit] - How many results a page holds: 50 by default, at most 100.
  @GET('/api/v1/categories/')
  Future<PaginatedCategoryList> categoryList({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  });

  /// Add a custom category.
  ///
  /// Needs an `Idempotency-Key`. A custom category is always of the kind `both` and has no `key`; a `kind` in the request is `400` `read_only`. The `icon` is one of the eight the picker offers (`400` `invalid_choice`). The name is unique among the person's custom categories in any case and is not a built-in key or English name (`400` `name_taken`). A person has at most 50 custom categories (`409` `category_limit_reached`); the built-in ones do not count.
  ///
  /// [idempotencyKey] - A random id, once per user action, as a quoted string of 16 to 64 letters, digits, hyphens or underscores (a UUID fits): `"8e03978e-40d5-43e8-bc93-6894a57f9324"`. Repeat the same request with the same key after a lost answer and nothing is created twice; the answer is replayed with `Idempotent-Replayed: true`. The key is honoured for 24 hours. Without it: `400` `idempotency_key_required` (`attr` `idempotency_key`).
  @POST('/api/v1/categories/')
  Future<Category> categoryCreate({
    @Header('Idempotency-Key') required String idempotencyKey,
    @Body() required CategoryInputRequest body,
  });

  /// Read a category.
  ///
  /// A built-in category or one of the person's own, or `404`. Answers the `ETag` of its `version`.
  @GET('/api/v1/categories/{id}/')
  Future<Category> categoryRead({@Path('id') required String id});

  /// Change a custom category.
  ///
  /// Changes `name` and `icon` of a custom category; `If-Match` is checked as for an account. A built-in category cannot be changed: `403` `category_is_builtin`. Any other field, `kind` included, is `400` `read_only`.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @PATCH('/api/v1/categories/{id}/')
  Future<Category> categoryUpdate({
    @Path('id') required String id,
    @Header('If-Match') String? ifMatch,
    @Body() PatchedCategoryInputRequest? body,
  });

  /// Delete a custom category.
  ///
  /// Deletes a custom category (`204`); its transactions move to the built-in `other` in the same database transaction (ADR 0017). `If-Match` is checked as for an account. A built-in category cannot be deleted: `403` `category_is_builtin`. A repeated delete is `404`: treat it as done.
  ///
  /// [ifMatch] - The `version` of the record the edit was made from, as a quoted string: `"3"` (`*` matches any record). If the stored version is another one nothing changes and the answer is `412` `precondition_failed`. Without the header the last write wins.
  @DELETE('/api/v1/categories/{id}/')
  Future<void> categoryDelete({
    @Path('id') required String id,
    @Header('If-Match') String? ifMatch,
  });
}
