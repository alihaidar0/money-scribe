import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/ids/uuid_v4.dart';

void main() {
  final format = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  test('has the shape of a version 4 UUID', () {
    for (var i = 0; i < 200; i++) {
      expect(generateUuidV4(Random(i)), matches(format));
    }
  });

  test('the secure source gives the same shape', () {
    expect(generateUuidV4(), matches(format));
  });

  test('is the same for the same random numbers, and different otherwise', () {
    expect(generateUuidV4(Random(7)), generateUuidV4(Random(7)));
    expect(generateUuidV4(Random(7)), isNot(generateUuidV4(Random(8))));
  });

  test('two secure ids never repeat', () {
    final ids = {for (var i = 0; i < 1000; i++) generateUuidV4()};

    expect(ids, hasLength(1000));
  });
}
