import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/network/write_safety_headers.dart';

void main() {
  test('the idempotency key is a quoted string', () {
    expect(
      WriteSafetyHeaders.idempotencyKey('0b9f2a8e-5c1d-4e7a-9a43-2f6d8c1e7b10'),
      '"0b9f2a8e-5c1d-4e7a-9a43-2f6d8c1e7b10"',
    );
  });

  test('If-Match carries the version as a quoted ETag', () {
    expect(WriteSafetyHeaders.ifMatch(3), '"3"');
    expect(WriteSafetyHeaders.ifMatch(1), '"1"');
  });

  test('If-None-Match asks for a record that does not exist yet', () {
    expect(WriteSafetyHeaders.ifNoneMatchAny, '*');
  });
}
