import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:money_scribe/core/clipboard/text_clipboard.dart';
import 'package:money_scribe/features/notifications/domain/notification_permission.dart';
import 'package:money_scribe/features/notifications/domain/push_messaging_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// The notification settings: the permission and, where `canCopyPushToken` is
/// set (staging builds), the push token for test messages.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  new({
    required PushMessagingRepository pushMessaging,
    required this._clipboard,
    required bool canCopyPushToken,
  }) : _pushMessaging = pushMessaging,
       super(
         NotificationsState(
           status: pushMessaging.isAvailable
               ? NotificationsStatus.loading
               : NotificationsStatus.unavailable,
           canCopyPushToken: canCopyPushToken,
         ),
       ) {
    // A second press while the first is still being handled is ignored, so the
    // user is never asked, or the clipboard written, twice at once.
    on<NotificationsStarted>(_onStarted, transformer: droppable());
    on<NotificationPermissionRequested>(
      _onPermissionRequested,
      transformer: droppable(),
    );
    on<PushTokenCopyRequested>(
      _onPushTokenCopyRequested,
      transformer: droppable(),
    );
  }

  final PushMessagingRepository _pushMessaging;
  final TextClipboard _clipboard;

  Future<void> _onStarted(
    NotificationsStarted event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.status == NotificationsStatus.unavailable) return;
    await _updatePermission(_pushMessaging.permission, emit);
  }

  Future<void> _onPermissionRequested(
    NotificationPermissionRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state.status == NotificationsStatus.unavailable) return;
    await _updatePermission(_pushMessaging.requestPermission, emit);
  }

  Future<void> _updatePermission(
    Future<NotificationPermission> Function() read,
    Emitter<NotificationsState> emit,
  ) async {
    try {
      final permission = await read();
      emit(
        state.copyWith(
          status: NotificationsStatus.ready,
          permission: permission,
        ),
      );
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: NotificationsStatus.failure));
    }
  }

  Future<void> _onPushTokenCopyRequested(
    PushTokenCopyRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    if (!state.canCopyPushToken) return;
    emit(state.copyWith(tokenCopy: PushTokenCopyStatus.copying));
    try {
      final token = await _pushMessaging.token();
      if (token == null) {
        emit(state.copyWith(tokenCopy: PushTokenCopyStatus.missing));
        return;
      }
      await _clipboard.copy(token);
      emit(state.copyWith(tokenCopy: PushTokenCopyStatus.copied));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(tokenCopy: PushTokenCopyStatus.failure));
    }
  }
}
