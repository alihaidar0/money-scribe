import 'package:flutter/material.dart';
import 'package:money_scribe/core/challenge/challenge_view_factory.dart';

/// A challenge that tests solve or fail by hand, with no web view. Each
/// widget it builds is remembered, so a test can see how many were asked for.
class FakeChallengeViewFactory implements ChallengeViewFactory {
  new({this.isAvailable = true});

  @override
  final bool isAvailable;

  /// The keys of the widgets built so far, oldest first.
  final built = <Key?>[];

  late ValueChanged<String> _onSolved;
  late VoidCallback _onFailed;

  /// The person solves the challenge.
  void solve(String token) => _onSolved(token);

  /// The challenge cannot be shown.
  void fail() => _onFailed();

  @override
  Widget build(
    BuildContext context, {
    required String action,
    required ValueChanged<String> onSolved,
    required VoidCallback onFailed,
    Key? key,
  }) {
    built.add(key);
    _onSolved = onSolved;
    _onFailed = onFailed;
    return const SizedBox(key: Key('fake-challenge'), height: 80, width: 300);
  }
}
