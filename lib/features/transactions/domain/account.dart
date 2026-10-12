import 'package:equatable/equatable.dart';

/// What kind of money an account holds.
enum AccountKind { card, cash }

/// Where money is kept, such as a card or cash.
final class Account extends Equatable {
  const new({required this.id, required this.name, required this.kind});

  final String id;
  final String name;
  final AccountKind kind;

  @override
  List<Object> get props => [id, name, kind];
}
