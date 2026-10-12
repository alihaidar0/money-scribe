import 'package:equatable/equatable.dart';

/// What kind of money an account holds.
enum AccountKind { card, cash, other }

/// Where money is kept, such as a card or cash.
final class Account extends Equatable {
  const new({required this.id, required this.name, required this.kind});

  final String id;
  final String name;
  final AccountKind kind;

  @override
  List<Object> get props => [id, name, kind];
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
