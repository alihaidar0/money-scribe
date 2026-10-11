part of 'notifications_bloc.dart';

enum NotificationsStatus {
  /// The permission is being read.
  loading,

  /// Push is not set up in this build: the settings are hidden.
  unavailable,

  /// The permission is known.
  ready,

  /// The permission could not be read or asked for.
  failure,
}

/// Where copying the push token stands. Each attempt goes through
/// [copying], so the same result twice in a row is still a change the
/// screen can react to.
enum PushTokenCopyStatus { idle, copying, copied, missing, failure }

final class NotificationsState extends Equatable {
  const new({
    required this.status,
    required this.canCopyPushToken,
    this.permission = NotificationPermission.notGranted,
    this.tokenCopy = PushTokenCopyStatus.idle,
  });

  final NotificationsStatus status;

  /// Whether this build offers to copy the push token (not in production).
  final bool canCopyPushToken;

  final NotificationPermission permission;
  final PushTokenCopyStatus tokenCopy;

  NotificationsState copyWith({
    NotificationsStatus? status,
    NotificationPermission? permission,
    PushTokenCopyStatus? tokenCopy,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      canCopyPushToken: canCopyPushToken,
      permission: permission ?? this.permission,
      tokenCopy: tokenCopy ?? this.tokenCopy,
    );
  }

  @override
  List<Object> get props => [status, canCopyPushToken, permission, tokenCopy];
}
