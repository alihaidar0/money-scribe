import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/settings/domain/account_locale_repository.dart';

/// An account locale repository that only counts how often it was asked.
class FakeAccountLocaleRepository implements AccountLocaleRepository {
  new({this.failure});

  /// Thrown by every [sync], to see how a caller copes with a server that
  /// cannot be reached.
  final DataException? failure;

  int syncs = 0;

  @override
  Future<void> sync() async {
    syncs++;
    final failure = this.failure;
    if (failure != null) throw failure;
  }
}
