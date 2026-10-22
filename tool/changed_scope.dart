// @dart=3.13
// Picks the tests a change needs.
//
// Reads the change from standard input, one `<status>\t<path>` per line (the
// output of `git diff --cached --name-status --no-renames`), looks at the
// import graph of lib/, test/ and tool/, and prints what to run:
//
//   scope: none            nothing that a test depends on changed
//   scope: tests           run exactly the `test:` files listed after it
//   scope: full            run the whole suite
//   reason: ...            why
//   test: test/x_test.dart one line per selected test
//
// A test is selected when it imports a changed file, directly or through any
// chain of imports, or when it is itself changed. Whenever the change is
// something the graph cannot see (a deleted file, the dependencies, the
// strings, the assets, the analyzer settings) the answer is `full`, so a doubt
// never skips a test. CI runs the whole suite anyway; this only keeps the
// commit hook quick.
//
// Usage: git diff --cached --name-status --no-renames | dart run tool/changed_scope.dart
import 'dart:io';

/// What to run.
enum ScopeKind { none, tests, full }

/// The answer: what to run, and why.
final class Scope {
  const new(this.kind, this.reason, [this.tests = const <String>[]]);

  final ScopeKind kind;
  final String reason;

  /// The test files to run, for [ScopeKind.tests].
  final List<String> tests;
}

/// One line of the change: a path and whether it was deleted.
final class Change {
  const new(this.path, {required this.deleted});

  /// Reads `M\tlib/a.dart`, `D\tlib/b.dart`, or a bare path (as modified).
  factory parse(String line) {
    final trimmed = line.trim();
    final tab = trimmed.indexOf('\t');
    if (tab == -1) return Change(_normalize(trimmed), deleted: false);
    final status = trimmed.substring(0, tab);
    return Change(
      _normalize(trimmed.substring(tab + 1)),
      deleted: status.startsWith('D'),
    );
  }

  final String path;
  final bool deleted;
}

/// Files whose change forces the whole suite: the tests read them from disk or
/// they change how every test is built, so no import chain describes them.
bool _forcesFullRun(String path) {
  return switch (path) {
    'pubspec.yaml' ||
    'pubspec.lock' ||
    'analysis_options.yaml' ||
    'l10n.yaml' ||
    'dart_test.yaml' => true,
    _ => path.endsWith('.arb') || path.startsWith('assets/'),
  };
}

/// Data files that a test reads from disk, and the Dart file that reads them.
/// A change to the data counts as a change to that file.
const _readers = <String, List<String>>{
  'docs/DESIGN.md': ['test/app/theme/design_file_parser.dart'],
};

final _directive = RegExp(
  r'''^\s*(?:import|export|part(?:\s+of)?)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

String _normalize(String path) {
  var result = path.replaceAll(r'\', '/');
  while (result.startsWith('./')) {
    result = result.substring(2);
  }
  return result;
}

bool _isSource(String path) {
  return path.endsWith('.dart') &&
      (path.startsWith('lib/') ||
          path.startsWith('test/') ||
          path.startsWith('tool/'));
}

bool _isTest(String path) {
  return path.startsWith('test/') && path.endsWith('_test.dart');
}

/// The Dart files under [root]'s lib/, test/ and tool/, as relative paths.
List<String> listSources(String root) {
  final files = <String>[];
  for (final folder in const ['lib', 'test', 'tool']) {
    final directory = Directory('$root/$folder');
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) continue;
      final relative = _normalize(entity.path.substring(root.length + 1));
      if (_isSource(relative)) files.add(relative);
    }
  }
  return files;
}

/// Who imports whom: for every file, the files that depend on it. A `part`
/// and its library depend on each other, because they are one unit.
Map<String, Set<String>> buildDependents(String root, List<String> sources) {
  final known = sources.toSet();
  final dependents = <String, Set<String>>{
    for (final source in sources) source: <String>{},
  };

  void link({required String dependency, required String dependent}) {
    if (!known.contains(dependency)) return;
    dependents[dependency]!.add(dependent);
  }

  for (final source in sources) {
    final text = File('$root/$source').readAsStringSync();
    for (final match in _directive.allMatches(text)) {
      final target = match.group(1)!;
      final directive = match.group(0)!.trimLeft();
      final String? resolved;
      if (target.startsWith('package:money_scribe/')) {
        resolved = 'lib/${target.substring('package:money_scribe/'.length)}';
      } else if (target.contains(':')) {
        resolved = null; // dart:, another package
      } else {
        resolved = _resolve(source, target);
      }
      if (resolved == null) continue;

      link(dependency: resolved, dependent: source);
      if (directive.startsWith('part')) {
        link(dependency: source, dependent: resolved);
      }
    }
  }
  return dependents;
}

/// [target] relative to the folder of [from], with `..` and `.` resolved.
String _resolve(String from, String target) {
  final parts = from.split('/')..removeLast();
  for (final segment in target.split('/')) {
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else if (segment != '.' && segment.isNotEmpty) {
      parts.add(segment);
    }
  }
  return parts.join('/');
}

/// Decides what to run for [changes], with the project in [root].
Scope computeScope({required String root, required List<Change> changes}) {
  if (changes.isEmpty) return const Scope(ScopeKind.none, 'no changed files');

  for (final change in changes) {
    if (_forcesFullRun(change.path)) {
      return Scope(ScopeKind.full, '${change.path} changed');
    }
    // A deleted file is no longer in the graph, so nothing says who needed it.
    if (change.deleted && _isSource(change.path)) {
      return Scope(ScopeKind.full, '${change.path} was deleted');
    }
  }

  final sources = listSources(root);
  final known = sources.toSet();
  final start = <String>{};
  var libraryChanged = false;

  for (final change in changes) {
    final path = change.path;
    if (_isSource(path)) {
      if (!known.contains(path)) {
        return Scope(ScopeKind.full, '$path is not where it was expected');
      }
      start.add(path);
      if (path.startsWith('lib/')) libraryChanged = true;
    }
    for (final reader in _readers[path] ?? const <String>[]) {
      if (known.contains(reader)) start.add(reader);
    }
  }

  if (start.isEmpty) {
    return const Scope(
      ScopeKind.none,
      'no changed file is code, or read by a test',
    );
  }

  final dependents = buildDependents(root, sources);
  final affected = <String>{...start};
  final queue = [...start];
  while (queue.isNotEmpty) {
    final next = queue.removeLast();
    for (final dependent in dependents[next] ?? const <String>{}) {
      if (affected.add(dependent)) queue.add(dependent);
    }
  }

  final tests = {
    for (final path in affected)
      if (_isTest(path)) path,
    // It reads every file of lib/ from disk, so any change there matters.
    if (libraryChanged && known.contains('test/architecture_test.dart'))
      'test/architecture_test.dart',
  }.toList()..sort();

  if (tests.isEmpty) {
    return const Scope(
      ScopeKind.full,
      'no test imports the changed files, so none can be ruled out',
    );
  }
  return Scope(
    ScopeKind.tests,
    '${start.length} changed file(s) reach ${tests.length} test file(s)',
    tests,
  );
}

/// The text the hook reads.
String describe(Scope scope) {
  final buffer = StringBuffer()
    ..writeln('scope: ${scope.kind.name}')
    ..writeln('reason: ${scope.reason}');
  for (final test in scope.tests) {
    buffer.writeln('test: $test');
  }
  return buffer.toString();
}

Future<void> main(List<String> arguments) async {
  final root = arguments.isEmpty ? Directory.current.path : arguments.first;
  final lines = <String>[];
  String? line;
  while ((line = stdin.readLineSync()) != null) {
    if (line!.trim().isNotEmpty) lines.add(line);
  }
  final scope = computeScope(
    root: root,
    changes: [for (final text in lines) Change.parse(text)],
  );
  stdout.write(describe(scope));
}
