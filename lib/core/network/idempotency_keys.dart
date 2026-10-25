import 'package:dio/dio.dart';
import 'package:money_scribe/core/ids/uuid_v4.dart';
import 'package:money_scribe/core/network/api_failure.dart';
import 'package:money_scribe/core/time/clock.dart';

/// Makes an `Idempotency-Key` for each action of the person, and keeps it for
/// as long as the action has no answer, so a retry of the same action is
/// recognised by the server and creates nothing twice.
///
/// An action is the person pressing Save, Add or Import once. The key is kept
/// while the answer is unknown (the connection dropped, the server failed or
/// was busy, the first try was still running) and forgotten as soon as there is
/// a final answer: a success, or a refusal that no retry changes. Two
/// presses of Save that each got an answer are two actions with two keys, so a
/// second purchase with the same amount is never taken for a repeat of the
/// first.
///
/// What names an action is the `action` text the repository builds from the
/// operation and what is being sent. It lives in memory only, so nothing the
/// person typed is kept anywhere.
class IdempotencyKeys {
  new({
    this._clock = const SystemClock(),
    String Function()? newKey,
    this.lifetime = defaultLifetime,
    this.capacity = defaultCapacity,
  }) : _newKey = newKey ?? generateUuidV4;

  /// The server forgets a key after 24 hours; a key is not reused after a
  /// little less, so a retry never meets a key the server has dropped.
  static const defaultLifetime = Duration(hours: 20);

  /// The most actions waiting for an answer at once.
  static const defaultCapacity = 100;

  final Clock _clock;
  final String Function() _newKey;
  final Duration lifetime;
  final int capacity;

  final _pending = <String, _Pending>{};

  /// The key of [action]: the one of an earlier try that has no answer yet, or
  /// a new one.
  String keyFor(String action) {
    final now = _clock.now();
    _pending.removeWhere(
      (_, pending) => now.difference(pending.since) > lifetime,
    );

    final existing = _pending[action];
    if (existing != null) return existing.key;

    if (_pending.length >= capacity) {
      // The oldest wait is the least likely to be retried.
      _pending.remove(_pending.keys.first);
    }
    final key = _newKey();
    _pending[action] = _Pending(key, now);
    return key;
  }

  /// [action] has its answer: its key is not used again.
  void settle(String action) => _pending.remove(action);

  /// Whether [action] has a key waiting for an answer.
  bool isPending(String action) => _pending.containsKey(action);

  /// Sends the action with its key: [send] gets the key and does the request.
  /// A success, or a final refusal, ends the action; anything else leaves the
  /// key for the retry. The failure is passed on as it came.
  Future<T> run<T>(String action, Future<T> Function(String key) send) async {
    final key = keyFor(action);
    try {
      final result = await send(key);
      settle(action);
      return result;
    } on DioException catch (error) {
      if (isFinal(ApiFailure.from(error))) settle(action);
      rethrow;
    }
  }

  /// Whether [failure] is an answer no retry changes: the server looked at the
  /// request and refused it. No answer at all, a server that failed or was
  /// busy, a try still running (`409 idempotency_in_progress`) and a request
  /// that has to wait (`429`, `408`) can all succeed when sent again, so their
  /// key stays.
  static bool isFinal(ApiFailure failure) {
    if (!failure.reachedServer) return false;
    final status = failure.statusCode ?? 0;
    if (status < 400 || status >= 500) return false;
    if (status == 408 || status == 429) return false;
    if (status == 409 && failure.hasCode('idempotency_in_progress')) {
      return false;
    }
    return true;
  }
}

class _Pending {
  const new(this.key, this.since);

  final String key;
  final DateTime since;
}
