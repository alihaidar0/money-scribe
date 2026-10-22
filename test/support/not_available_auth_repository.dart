import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';

/// An account whose server does not offer changing the password or deleting
/// the account yet, as the real one answers today.
class NotAvailableAuthRepository extends FakeAuthRepository {
  new({required super.demo, super.signedIn});

  @override
  Future<void> changePassword({required String current, required String next}) {
    throw const FeatureNotAvailableException();
  }

  @override
  Future<void> deleteAccount({required String password}) {
    throw const FeatureNotAvailableException();
  }
}
