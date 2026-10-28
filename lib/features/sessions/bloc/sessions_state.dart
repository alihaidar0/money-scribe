part of 'sessions_bloc.dart';

/// The two tabs of the screen.
enum SessionsTab { active, previous }

enum SessionsStatus {
  /// The active sessions are being loaded.
  loading,

  /// The active sessions are shown.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

enum PreviousStatus {
  /// The tab was not opened yet, so nothing was asked.
  idle,

  /// The first page of the ended sessions is being loaded.
  loading,

  /// The ended sessions are shown, or there are none.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class SessionsState extends Equatable {
  const new({
    this.tab = SessionsTab.active,
    this.status = SessionsStatus.loading,
    this.active = const [],
    this.previousStatus = PreviousStatus.idle,
    this.previous = const [],
    this.previousNext,
    this.loadingMore = false,
    this.loadMoreFailed = false,
    this.endingId,
    this.endedCount = 0,
    this.failedAction,
  });

  final SessionsTab tab;
  final SessionsStatus status;

  /// The sessions that are active, the current one first.
  final List<DeviceSession> active;

  final PreviousStatus previousStatus;

  /// The ended sessions loaded so far, newest sign-in first.
  final List<DeviceSession> previous;

  /// What the server gave to ask for the next page of ended sessions, or
  /// `null` on the last page.
  final String? previousNext;

  /// Whether the next page of ended sessions is being loaded.
  final bool loadingMore;

  /// Whether the next page of ended sessions could not be loaded.
  final bool loadMoreFailed;

  /// The session being ended.
  final String? endingId;

  /// How many sessions the person ended. It goes up with each one, so the
  /// screen can say "Session ended" for each.
  final int endedCount;

  /// The end of a session that did not work, so the screen can offer to try
  /// again. `null` once something else was done.
  final SessionEndConfirmed? failedAction;

  /// The ended sessions grouped by device.
  List<DeviceSessionGroup> get previousGroups {
    return DeviceSessionGroup.group(previous);
  }

  /// The active sessions of the other devices, which can be signed out.
  List<DeviceSession> get others {
    return [
      for (final session in active)
        if (!session.isCurrent) session,
    ];
  }

  SessionsState copyWith({
    SessionsTab? tab,
    SessionsStatus? status,
    List<DeviceSession>? active,
    PreviousStatus? previousStatus,
    List<DeviceSession>? previous,
    String? previousNext,
    bool clearPreviousNext = false,
    bool? loadingMore,
    bool? loadMoreFailed,
    String? endingId,
    bool clearEndingId = false,
    int? endedCount,
    SessionEndConfirmed? failedAction,
    bool clearFailedAction = false,
  }) {
    return SessionsState(
      tab: tab ?? this.tab,
      status: status ?? this.status,
      active: active ?? this.active,
      previousStatus: previousStatus ?? this.previousStatus,
      previous: previous ?? this.previous,
      previousNext: clearPreviousNext
          ? null
          : previousNext ?? this.previousNext,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      endingId: clearEndingId ? null : endingId ?? this.endingId,
      endedCount: endedCount ?? this.endedCount,
      failedAction: clearFailedAction
          ? null
          : failedAction ?? this.failedAction,
    );
  }

  @override
  List<Object?> get props => [
    tab,
    status,
    active,
    previousStatus,
    previous,
    previousNext,
    loadingMore,
    loadMoreFailed,
    endingId,
    endedCount,
    failedAction,
  ];
}
