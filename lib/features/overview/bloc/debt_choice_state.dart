part of 'debt_choice_bloc.dart';

enum DebtChoiceStatus { loading, ready, noConnection, failure }

final class DebtChoiceState extends Equatable {
  const new({
    this.status = DebtChoiceStatus.loading,
    this.debts = const <DebtChoice>[],
  });

  final DebtChoiceStatus status;
  final List<DebtChoice> debts;

  @override
  List<Object> get props => [status, debts];
}
