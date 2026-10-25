part of 'server_wake_bloc.dart';

final class ServerWakeState extends Equatable {
  const new({this.isWaking = false});

  /// A request has been waiting for the server for a few seconds: the person
  /// is told that it is starting.
  final bool isWaking;

  @override
  List<Object> get props => [isWaking];
}
