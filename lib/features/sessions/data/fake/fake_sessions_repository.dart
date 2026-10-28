import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/time/clock.dart';
import 'package:money_scribe/features/sessions/data/fake/sessions_seed.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';
import 'package:money_scribe/features/sessions/domain/sessions_repository.dart';

/// Sessions and activity made of invented devices, until the server exists. It
/// follows the demo panel: no data (an account that has only this device),
/// slow, failing or offline, and a password that is wrong. What the app ends is
/// kept in memory for as long as it runs.
///
/// It keeps the rules of the server: the ended sessions and the activity come
/// in pages, a session that ends moves to the ended ones, and ending another
/// device is for another device only.
class FakeSessionsRepository implements SessionsRepository {
  new({
    required this._demo,
    this.pageSize = defaultPageSize,
    this._clock = const SystemClock(),
  });

  /// How many ended sessions and activity entries a page holds.
  static const defaultPageSize = 50;

  final DemoController _demo;
  final int pageSize;
  final Clock _clock;

  /// What the app changed since it started; it replaces the seed.
  List<DeviceSession>? _active;
  List<DeviceSession>? _ended;

  @override
  Stream<void> get changes => _demo.dataChanges;

  @override
  Future<List<DeviceSession>> active() async {
    await _demo.simulateRequest();
    return List.unmodifiable(_activeNow());
  }

  @override
  Future<SessionsPage> ended({String? cursor}) async {
    await _demo.simulateRequest();
    final all = _endedNow();
    final start = _offsetOf(cursor);
    final end = start + pageSize;
    return SessionsPage(
      items: List.unmodifiable(all.skip(start).take(pageSize)),
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  @override
  Future<void> end(String id) async {
    await _demo.simulateSave();
    final sessions = _activeNow();
    final found = sessions.where((session) => session.id == id);
    // Already ended: the person wanted it ended.
    if (found.isEmpty || found.first.isCurrent) return;
    _active = [
      for (final session in sessions)
        if (session.id != id) session,
    ];
    _ended = [
      found.first.endedBy(SessionEndReason.revokedByUser, _clock.now()),
      ..._endedNow(),
    ];
  }

  @override
  Future<OthersSignedOut> endOthers({required String password}) async {
    await _demo.simulateSave();
    if (_demo.settings.signIn == DemoSignIn.wrongPassword) {
      throw const SessionRefusedException(SessionRefusal.wrongPassword);
    }
    final sessions = _activeNow();
    final others = [
      for (final session in sessions)
        if (!session.isCurrent) session,
    ];
    _active = [
      for (final session in sessions)
        if (session.isCurrent) session,
    ];
    final now = _clock.now();
    _ended = [
      for (final session in others)
        session.endedBy(SessionEndReason.revokedByUser, now),
      ..._endedNow(),
    ];
    return OthersSignedOut(
      sessionsEnded: others.length,
      keysRemoved: others.length,
    );
  }

  @override
  Future<SecurityEventsPage> activity({String? cursor}) async {
    await _demo.simulateRequest();
    final all = _isEmpty ? const <SecurityEvent>[] : SessionsSeed.activity();
    final start = _offsetOf(cursor);
    final end = start + pageSize;
    return SecurityEventsPage(
      items: List.unmodifiable(all.skip(start).take(pageSize)),
      nextCursor: end < all.length ? '$end' : null,
    );
  }

  bool get _isEmpty => _demo.settings.scenario == DemoScenario.empty;

  int _offsetOf(String? cursor) => int.tryParse(cursor ?? '') ?? 0;

  List<DeviceSession> _activeNow() {
    return _active ??
        (_isEmpty ? SessionsSeed.onlyCurrent() : SessionsSeed.active());
  }

  List<DeviceSession> _endedNow() {
    return _ended ?? (_isEmpty ? const [] : SessionsSeed.ended());
  }
}
