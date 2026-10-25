import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/changed_scope.dart';

/// A small project on disk: `files` maps a path to its source.
Directory _project(Map<String, String> files) {
  final root = Directory.systemTemp.createTempSync('changed_scope_');
  addTearDown(() => root.deleteSync(recursive: true));
  files.forEach((path, source) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(source);
  });
  return root;
}

Scope _scope(Directory root, List<String> lines) {
  return computeScope(
    root: root.path,
    changes: [for (final line in lines) Change.parse(line)],
  );
}

void main() {
  // lib/a.dart <- lib/b.dart <- test/b_test.dart, and lib/c.dart <- test/c_test.dart.
  Directory chain() => _project({
    'lib/a.dart': 'int a = 1;\n',
    'lib/b.dart': "import 'a.dart';\nint b = a;\n",
    'lib/c.dart': 'int c = 3;\n',
    'test/b_test.dart':
        "import 'package:money_scribe/b.dart';\nvoid main() {}\n",
    'test/c_test.dart': "import '../lib/c.dart';\nvoid main() {}\n",
    'test/architecture_test.dart': 'void main() {}\n',
  });

  group('a change nothing depends on', () {
    test('no changed file means nothing to run', () {
      final scope = computeScope(root: chain().path, changes: const []);

      expect(scope.kind, ScopeKind.none);
    });

    test('documentation, workflows and scripts select nothing', () {
      final scope = _scope(chain(), [
        'M\tdocs/steps.md',
        'M\tREADME.md',
        'M\t.github/workflows/build.yml',
        'A\tscripts/welcome.sh',
      ]);

      expect(scope.kind, ScopeKind.none);
      expect(scope.tests, isEmpty);
    });
  });

  group('the import graph', () {
    test(
      'selects the tests that import the changed file, through any chain',
      () {
        final scope = _scope(chain(), ['M\tlib/a.dart']);

        expect(scope.kind, ScopeKind.tests);
        // a <- b <- b_test, plus the test that reads all of lib/.
        expect(scope.tests, [
          'test/architecture_test.dart',
          'test/b_test.dart',
        ]);
      },
    );

    test('leaves out the tests of unrelated code', () {
      final scope = _scope(chain(), ['M\tlib/c.dart']);

      expect(scope.tests, ['test/architecture_test.dart', 'test/c_test.dart']);
      expect(scope.tests, isNot(contains('test/b_test.dart')));
    });

    test('follows package and relative imports alike', () {
      final scope = _scope(chain(), ['M\tlib/b.dart', 'M\tlib/c.dart']);

      expect(
        scope.tests,
        containsAll(['test/b_test.dart', 'test/c_test.dart']),
      );
    });

    test('follows an export', () {
      final root = _project({
        'lib/a.dart': 'int a = 1;\n',
        'lib/api.dart': "export 'a.dart';\n",
        'test/api_test.dart': "import 'package:money_scribe/api.dart';\n",
      });

      final scope = _scope(root, ['M\tlib/a.dart']);

      expect(scope.tests, contains('test/api_test.dart'));
    });

    test('treats a part and its library as one unit, in both directions', () {
      final root = _project({
        'lib/bloc.dart': "part 'bloc_state.dart';\nclass Bloc {}\n",
        'lib/bloc_state.dart': "part of 'bloc.dart';\nclass State {}\n",
        'test/bloc_test.dart': "import 'package:money_scribe/bloc.dart';\n",
      });

      final fromPart = _scope(root, ['M\tlib/bloc_state.dart']);
      final fromLibrary = _scope(root, ['M\tlib/bloc.dart']);

      expect(fromPart.tests, contains('test/bloc_test.dart'));
      expect(fromLibrary.tests, contains('test/bloc_test.dart'));
    });

    test('ignores dart: and other packages, and survives a cycle', () {
      final root = _project({
        'lib/a.dart':
            "import 'dart:io';\nimport 'package:flutter/widgets.dart';\n"
            "import 'b.dart';\n",
        'lib/b.dart': "import 'a.dart';\n",
        'test/a_test.dart': "import 'package:money_scribe/a.dart';\n",
      });

      final scope = _scope(root, ['M\tlib/b.dart']);

      expect(scope.tests, contains('test/a_test.dart'));
    });

    test('reads double-quoted directives', () {
      final root = _project({
        'lib/a.dart': 'int a = 1;\n',
        'test/a_test.dart': 'import "package:money_scribe/a.dart";\n',
      });

      expect(
        _scope(root, ['M\tlib/a.dart']).tests,
        contains('test/a_test.dart'),
      );
    });
  });

  group('a change to a test', () {
    test('selects that test and nothing else', () {
      final scope = _scope(chain(), ['M\ttest/c_test.dart']);

      expect(scope.kind, ScopeKind.tests);
      expect(scope.tests, ['test/c_test.dart']);
    });

    test('in the support code selects the tests that use it', () {
      final root = _project({
        'test/support/fake.dart': 'class Fake {}\n',
        'test/x_test.dart': "import 'support/fake.dart';\n",
        'test/y_test.dart': 'void main() {}\n',
      });

      final scope = _scope(root, ['M\ttest/support/fake.dart']);

      expect(scope.tests, ['test/x_test.dart']);
    });
  });

  group('the test that reads all of lib/', () {
    test('is added whenever a file of lib/ changes', () {
      final scope = _scope(chain(), ['M\tlib/c.dart']);

      expect(scope.tests, contains('test/architecture_test.dart'));
    });

    test('is not added for a change in a test', () {
      final scope = _scope(chain(), ['M\ttest/b_test.dart']);

      expect(scope.tests, isNot(contains('test/architecture_test.dart')));
    });
  });

  group('a file that a test reads from disk', () {
    test('counts as a change to the file that reads it', () {
      final root = _project({
        'test/app/theme/design_file_parser.dart': 'class Parser {}\n',
        'test/app/theme/colors_test.dart':
            "import 'design_file_parser.dart';\n",
        'test/other_test.dart': 'void main() {}\n',
      });

      final scope = _scope(root, ['M\tdocs/DESIGN.md']);

      expect(scope.kind, ScopeKind.tests);
      expect(scope.tests, ['test/app/theme/colors_test.dart']);
    });
  });

  group('the whole suite is the answer when the graph cannot say', () {
    for (final path in [
      'pubspec.yaml',
      'pubspec.lock',
      'analysis_options.yaml',
      'l10n.yaml',
      'dart_test.yaml',
      'lib/core/l10n/arb/app_en.arb',
      'assets/fonts/Inter-Regular.ttf',
    ]) {
      test('$path changed', () {
        final scope = _scope(chain(), ['M\t$path']);

        expect(scope.kind, ScopeKind.full);
        expect(scope.reason, contains(path));
      });
    }

    test('a Dart file was deleted', () {
      final scope = _scope(chain(), ['D\tlib/a.dart']);

      expect(scope.kind, ScopeKind.full);
      expect(scope.reason, contains('deleted'));
    });

    test('a deleted test is no reason to run anything else... but is safe', () {
      final scope = _scope(chain(), ['D\ttest/c_test.dart']);

      expect(scope.kind, ScopeKind.full);
    });

    test('a changed file is missing from the disk', () {
      final scope = _scope(chain(), ['M\tlib/not_there.dart']);

      expect(scope.kind, ScopeKind.full);
    });

    test('no test imports the changed code and nothing else can be said', () {
      final root = _project({
        'lib/lonely.dart': 'int x = 1;\n',
        'test/y_test.dart': 'void main() {}\n',
      });

      final scope = _scope(root, ['M\tlib/lonely.dart']);

      expect(scope.kind, ScopeKind.full);
    });

    test('a deleted document is no change to code', () {
      final scope = _scope(chain(), ['D\tdocs/old.md']);

      expect(scope.kind, ScopeKind.none);
    });
  });

  group('reading the change', () {
    test('a status and a path', () {
      final change = Change.parse('M\tlib/a.dart');

      expect(change.path, 'lib/a.dart');
      expect(change.deleted, isFalse);
    });

    test('a deletion', () {
      expect(Change.parse('D\tlib/a.dart').deleted, isTrue);
    });

    test('a bare path is a modification', () {
      final change = Change.parse('lib/a.dart');

      expect(change.path, 'lib/a.dart');
      expect(change.deleted, isFalse);
    });

    test('a leading ./ and backslashes are tidied', () {
      expect(Change.parse('M\t./lib/a.dart').path, 'lib/a.dart');
      expect(Change.parse(r'M	lib\core\a.dart').path, 'lib/core/a.dart');
    });
  });

  group('what the hook reads', () {
    test('names the scope, the reason and each test', () {
      const scope = Scope(ScopeKind.tests, 'why', ['test/a_test.dart']);

      expect(
        describe(scope),
        'scope: tests\nreason: why\ntest: test/a_test.dart\n',
      );
    });

    test('has no test lines for none and full', () {
      expect(
        describe(const Scope(ScopeKind.none, 'nothing')),
        'scope: none\nreason: nothing\n',
      );
      expect(
        describe(const Scope(ScopeKind.full, 'all')),
        'scope: full\nreason: all\n',
      );
    });
  });

  test('works on this repository: a docs change selects nothing', () {
    final scope = computeScope(
      root: Directory.current.path,
      changes: [Change.parse('M\tdocs/steps.md')],
    );

    expect(scope.kind, ScopeKind.none);
  });

  test('works on this repository: a leaf of core reaches its own tests', () {
    final scope = computeScope(
      root: Directory.current.path,
      changes: [Change.parse('M\tlib/core/network/slow_request_monitor.dart')],
    );

    expect(scope.kind, ScopeKind.tests);
    expect(
      scope.tests,
      contains('test/core/network/slow_request_monitor_test.dart'),
    );
    expect(scope.tests, isNot(contains('test/features/debts')));
  });
}
