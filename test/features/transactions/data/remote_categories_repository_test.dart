import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/network/idempotency_keys.dart';
import 'package:money_scribe/features/transactions/data/remote/remote_categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

import '../../../support/fake_http_adapter.dart';
import 'transactions_json.dart';

const _id = '0198f2a9-1d20-7c44-b6a1-2f8e3c5d7a90';
const _draft = CategoryDraft(name: 'Pets', icon: CategoryIcon.gifts);

void main() {
  late FakeHttpAdapter server;
  late ResponseBody Function(RequestOptions options) answer;
  late int keyCount;

  RemoteCategoriesRepository build() {
    return RemoteCategoriesRepository.create(
      dio: transactionsTestDio(server),
      keys: IdempotencyKeys(newKey: () => 'key-${++keyCount}-aaaaaaaaaaaa'),
    );
  }

  RequestOptions lastRequest() => server.requests.last;

  setUp(() {
    keyCount = 0;
    answer = (_) => jsonBody(200, categoryJson());
    server = FakeHttpAdapter((options) => answer(options));
  });

  group('categories', () {
    test('reads the built-in ones with their key, then the own ones', () async {
      answer = (_) => jsonBody(
        200,
        pageJson([
          categoryJson(
            id: 'g',
            name: 'Groceries',
            icon: 'groceries',
            kind: 'expense',
            key: 'groceries',
          ),
          categoryJson(
            id: 's',
            name: 'Scholarship',
            icon: 'scholarship',
            kind: 'income',
            key: 'scholarship',
          ),
          categoryJson(version: 3),
        ]),
      );

      final categories = await build().categories();

      expect(lastRequest().path, '/api/v1/categories/');
      expect(lastRequest().queryParameters['limit'], 100);
      expect(categories, [
        const TransactionCategory(
          id: 'g',
          name: 'Groceries',
          icon: CategoryIcon.groceries,
          key: 'groceries',
        ),
        const TransactionCategory(
          id: 's',
          name: 'Scholarship',
          icon: CategoryIcon.scholarship,
          kind: CategoryKind.income,
          key: 'scholarship',
        ),
        const TransactionCategory(
          id: _id,
          name: 'Pets',
          icon: CategoryIcon.gifts,
          kind: CategoryKind.both,
          isCustom: true,
          version: 3,
        ),
      ]);
    });

    test('an icon the app does not know is shown as Other', () async {
      answer = (_) =>
          jsonBody(200, pageJson([categoryJson(icon: 'rocket-ship')]));

      expect((await build().categories()).single.icon, CategoryIcon.other);
    });

    test('a kind the app does not know is for both', () async {
      answer = (_) => jsonBody(200, pageJson([categoryJson(kind: 'transfer')]));

      expect((await build().categories()).single.kind, CategoryKind.both);
    });

    test('never follows a next page on another server', () async {
      answer = (_) => jsonBody(
        200,
        pageJson([
          categoryJson(),
        ], next: 'https://evil.example.test/api/v1/categories/?cursor=abc'),
      );

      await expectLater(build().categories(), throwsA(isA<ServerException>()));
      expect(server.requests, hasLength(1));
    });
  });

  group('add', () {
    test('sends the name and icon with an Idempotency-Key', () async {
      answer = (_) => jsonBody(201, categoryJson());

      final category = await build().add(_draft);

      expect(lastRequest().method, 'POST');
      expect(lastRequest().path, '/api/v1/categories/');
      expect(lastRequest().data, {'name': 'Pets', 'icon': 'gifts'});
      expect(lastRequest().headers['Idempotency-Key'], '"key-1-aaaaaaaaaaaa"');
      expect(category.isCustom, isTrue);
      expect(category.kind, CategoryKind.both);
    });

    test('a retry after a lost answer uses the same key', () async {
      final repository = build();
      var lost = true;
      answer = (options) {
        if (lost) throw connectionLost(options);
        return jsonBody(201, categoryJson());
      };

      await expectLater(
        repository.add(_draft),
        throwsA(isA<NoConnectionException>()),
      );
      lost = false;
      await repository.add(_draft);

      expect(
        [for (final r in server.requests) r.headers['Idempotency-Key']],
        ['"key-1-aaaaaaaaaaaa"', '"key-1-aaaaaaaaaaaa"'],
      );
    });

    test('a name that is taken is a refusal the person can act on', () {
      answer = (_) => jsonBody(
        400,
        errorBody('name_taken', type: 'validation_error', attr: 'name'),
      );

      expect(
        build().add(_draft),
        throwsA(
          isA<CategoryRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            CategoryRefusal.nameTaken,
          ),
        ),
      );
    });

    test('the limit of categories is a refusal the person can act on', () {
      answer = (_) => jsonBody(409, errorBody('category_limit_reached'));

      expect(
        build().add(_draft),
        throwsA(
          isA<CategoryRefusedException>().having(
            (e) => e.refusal,
            'refusal',
            CategoryRefusal.limitReached,
          ),
        ),
      );
    });
  });

  group('update', () {
    test('sends the changes at the version they were made from', () async {
      answer = (_) => jsonBody(200, categoryJson(name: 'Cats', version: 2));

      final category = await build().update(
        _id,
        const CategoryDraft(name: 'Cats', icon: CategoryIcon.health),
        version: 1,
      );

      expect(lastRequest().method, 'PATCH');
      expect(lastRequest().path, '/api/v1/categories/$_id/');
      expect(lastRequest().headers['If-Match'], '"1"');
      expect(lastRequest().data, {'name': 'Cats', 'icon': 'health'});
      expect(category.version, 2);
    });

    test('a built-in category is refused and is a failure', () {
      answer = (_) => jsonBody(403, errorBody('category_is_builtin'));

      expect(
        build().update(_id, _draft, version: 1),
        throwsA(isA<ServerException>()),
      );
    });

    test('a version that moved on, or a category that is gone, is stale', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));
      expect(
        build().update(_id, _draft, version: 1),
        throwsA(isA<StaleRecordException>()),
      );

      answer = (_) => jsonBody(404, errorBody('not_found'));
      expect(
        build().update(_id, _draft, version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  group('delete', () {
    test('deletes at the version it was made from', () async {
      answer = (_) => jsonBody(204);

      await build().delete(_id, version: 2);

      expect(lastRequest().method, 'DELETE');
      expect(lastRequest().path, '/api/v1/categories/$_id/');
      expect(lastRequest().headers['If-Match'], '"2"');
    });

    test('a category that is already gone is deleted', () async {
      answer = (_) => jsonBody(404, errorBody('not_found'));

      await build().delete(_id, version: 2);
    });

    test('a built-in category cannot be deleted', () {
      answer = (_) => jsonBody(403, errorBody('category_is_builtin'));

      expect(build().delete(_id, version: 1), throwsA(isA<ServerException>()));
    });

    test('a version that moved on is a stale record', () {
      answer = (_) => jsonBody(412, errorBody('precondition_failed'));

      expect(
        build().delete(_id, version: 1),
        throwsA(isA<StaleRecordException>()),
      );
    });
  });

  test('tells when this device changed the categories', () async {
    final repository = build();
    final changes = <void>[];
    final subscription = repository.changes.listen(changes.add);
    addTearDown(subscription.cancel);
    answer = (_) => jsonBody(201, categoryJson());

    await repository.add(_draft);
    answer = (_) => jsonBody(204);
    await repository.delete(_id, version: 1);
    await Future<void>.delayed(Duration.zero);

    expect(changes, hasLength(2));
  });
}
