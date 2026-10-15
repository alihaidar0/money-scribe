part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const new();

  @override
  List<Object> get props => [];
}

/// The notification settings were opened: read the current permission.
final class NotificationsStarted extends NotificationsEvent {
  const new();
}

/// The user pressed Allow.
final class NotificationPermissionRequested extends NotificationsEvent {
  const new();
}

/// The user asked to copy the push token (staging builds only).
final class PushTokenCopyRequested extends NotificationsEvent {
  const new();
}
