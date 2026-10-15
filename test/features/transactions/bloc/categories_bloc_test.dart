import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/categories/category_icon.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/transactions/bloc/categories_bloc.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction_category.dart';

void main() {
  late DemoController demo;
  late FakeCategoriesRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeCategoriesRepository(demo: demo);
  });

  CategoriesBloc build() => CategoriesBloc(repository: repository);

  const draft = CategoryDraft(name: 'Pets', icon: CategoryIcon.health);

  Future<void> start(CategoriesBloc bloc) async {
    bloc.add(const CategoriesStarted());
    await Future<void>.delayed(Duration.zero);
  }

  group('CategoriesStarted', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'loads the built-in categories and the custom one',
      build: build,
      act: (bloc) => bloc.add(const CategoriesStarted()),
      verify: (bloc) {
        expect(bloc.state.status, CategoriesStatus.ready);
        expect(bloc.state.categories, hasLength(8));
        expect(
          bloc.state.categories.where((c) => c.isCustom).single.name,
          'Gifts',
        );
      },
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const CategoriesStarted()),
      verify: (bloc) =>
          expect(bloc.state.status, CategoriesStatus.noConnection),
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const CategoriesStarted()),
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, CategoriesStatus.failure),
    );
  });

  group('CategoryAdded', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'adds the category at the end of the list',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const CategoryAdded(draft));
      },
      verify: (bloc) {
        expect(bloc.state.categories, hasLength(9));
        expect(bloc.state.categories.last.name, 'Pets');
        expect(bloc.state.categories.last.isCustom, isTrue);
        expect(bloc.state.failedAction, isNull);
      },
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'keeps the list and the action when the server does not accept it',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const CategoryAdded(draft));
      },
      verify: (bloc) {
        expect(bloc.state.categories, hasLength(8));
        expect(bloc.state.failedAction, const CategoryAdded(draft));
      },
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'the failed action can be tried again',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const CategoryAdded(draft));
        await Future<void>.delayed(Duration.zero);
        demo.update(const DemoSettings());
        bloc.add(bloc.state.failedAction!);
      },
      verify: (bloc) {
        expect(bloc.state.categories, hasLength(9));
        expect(bloc.state.failedAction, isNull);
      },
    );
  });

  group('CategoryChanged', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'changes the name and the icon in place',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const CategoryChanged('gifts', draft));
      },
      verify: (bloc) {
        final category = bloc.state.categories.last;
        expect(category.id, 'gifts');
        expect(category.name, 'Pets');
        expect(category.icon, CategoryIcon.health);
        expect(bloc.state.categories, hasLength(8));
      },
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'a built-in category cannot be changed',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const CategoryChanged('groceries', draft));
      },
      errors: () => [isA<Exception>()],
      verify: (bloc) {
        expect(bloc.state.categories.first.name, 'Groceries');
        expect(
          bloc.state.failedAction,
          const CategoryChanged('groceries', draft),
        );
      },
    );
  });

  group('CategoryDeleted', () {
    blocTest<CategoriesBloc, CategoriesState>(
      'removes the category',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const CategoryDeleted('gifts'));
      },
      verify: (bloc) {
        expect(bloc.state.categories, hasLength(7));
        expect(
          bloc.state.categories.map((c) => c.id),
          isNot(contains('gifts')),
        );
      },
    );

    blocTest<CategoriesBloc, CategoriesState>(
      'reports no connection and keeps the category',
      build: build,
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
        bloc.add(const CategoryDeleted('gifts'));
      },
      verify: (bloc) {
        expect(bloc.state.categories, hasLength(8));
        expect(bloc.state.failedAction, const CategoryDeleted('gifts'));
      },
    );
  });
}
