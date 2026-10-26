import 'package:money_scribe/features/sessions/data/fake/fake_sessions_repository.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';

/// The fake sessions whose `endOthers` fails with [endOthersFailure] while it
/// is set, the way the server does when it asks the person to wait.
class RefusingSessionsRepository extends FakeSessionsRepository {
  new({required super.demo, this.endOthersFailure, super.pageSize});

  Exception? endOthersFailure;

  @override
  Future<OthersSignedOut> endOthers({required String password}) async {
    final error = endOthersFailure;
    if (error != null) throw error;
    final result = await super.endOthers(password: password);
    return result;
  }
}
