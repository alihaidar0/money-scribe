import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/device/random_uuid.dart';

void main() {
  test('has the shape of a version 4 UUID', () {
    for (var i = 0; i < 200; i++) {
      final id = randomUuidV4();

      expect(isUuidV4(id), isTrue, reason: id);
      expect(id, hasLength(36));
    }
  });

  test('is different every time', () {
    final ids = {for (var i = 0; i < 500; i++) randomUuidV4()};

    expect(ids, hasLength(500));
  });

  test('is the same for the same random source', () {
    expect(randomUuidV4(Random(7)), randomUuidV4(Random(7)));
  });

  test('sets the version and the variant bits', () {
    final id = randomUuidV4(Random(1));

    expect(id[14], '4');
    expect('89ab', contains(id[19]));
  });

  group('isUuidV4', () {
    test('accepts one and nothing else', () {
      expect(isUuidV4('0b9f2a8e-5c1d-4e7a-9a43-2f6d8c1e7b10'), isTrue);
      expect(isUuidV4(''), isFalse);
      expect(isUuidV4('not-a-uuid'), isFalse);
      expect(isUuidV4('0b9f2a8e-5c1d-1e7a-9a43-2f6d8c1e7b10'), isFalse);
      expect(isUuidV4('0B9F2A8E-5C1D-4E7A-9A43-2F6D8C1E7B10'), isFalse);
      expect(isUuidV4('0b9f2a8e-5c1d-4e7a-9a43-2f6d8c1e7b10 '), isFalse);
    });
  });
}
