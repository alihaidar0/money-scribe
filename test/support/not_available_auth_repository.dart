import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';

/// An account whose server does not offer deleting the account yet, as the
/// real one answers today.
class NotAvailableAuthRepository extends FakeAuthRepository {
  new({required super.demo, super.signedIn});

  @override
  Future<void> deleteAccount({required String password}) {
    throw const FeatureNotAvailableException();
  }
}
