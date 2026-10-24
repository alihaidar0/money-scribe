/// The headers that keep a write safe: the same request repeated does not
/// create a second record (`Idempotency-Key`), and an edit never overwrites a
/// change made on another device (`If-Match`, `If-None-Match`). The generated
/// client takes each as a plain string parameter; this is the one place that
/// says how the string is written.
abstract final class WriteSafetyHeaders {
  /// The value of `Idempotency-Key` for [key], a random UUID made for one
  /// action of the person (see `IdempotencyKeys`).
  static String idempotencyKey(String key) => '"$key"';

  /// The value of `If-Match` for an edit or a delete of the record that has
  /// [version]. A record that changed since answers `412`.
  static String ifMatch(int version) => '"$version"';

  /// The value of `If-None-Match` for creating a record with `PUT`: it must
  /// not exist yet, or the answer is `412` and nothing is replaced.
  static const ifNoneMatchAny = '*';
}
