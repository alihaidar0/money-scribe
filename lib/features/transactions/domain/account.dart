import 'package:equatable/equatable.dart';

/// What kind of money an account holds.
enum AccountKind { card, cash, other }

/// Where money is kept, such as a card or cash.
final class Account extends Equatable {
  const new({
    required this.id,
    required this.name,
    required this.kind,
    this.version = 1,
  });

  final String id;
  final String name;
  final AccountKind kind;

  /// The version of the record on the server, sent back with a change or a
  /// delete so a change made on another device in between is never
  /// overwritten.
  final int version;

  @override
  List<Object> get props => [id, name, kind, version];
}

/// An account as it is typed, before the server gives it an id.
final class AccountDraft extends Equatable {
  const new({required this.name, required this.kind});

  /// The most characters a name has.
  static const maxNameLength = 30;

  /// The draft of what was typed, or `null` while the name is empty or too
  /// long.
  static AccountDraft? tryCreate({
    required String name,
    required AccountKind kind,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > maxNameLength) return null;
    return AccountDraft(name: trimmed, kind: kind);
  }

  final String name;
  final AccountKind kind;

  @override
  List<Object> get props => [name, kind];
}

/// Thrown when an account that has transactions is deleted: they would be
/// left without an account.
final class AccountInUseException implements Exception {
  const new();

  @override
  String toString() => 'AccountInUseException';
}

/// Why the server did not accept an account the person typed.
enum AccountRefusal {
  /// Another account has this name (the names are compared in any case).
  nameTaken,

  /// The person has as many accounts as the server allows.
  limitReached,
}

/// Thrown when the server refuses an account for a reason the person can act
/// on.
final class AccountRefusedException implements Exception {
  const new(this.refusal);

  final AccountRefusal refusal;

  @override
  String toString() => 'AccountRefusedException($refusal)';
}
