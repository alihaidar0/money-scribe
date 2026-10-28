part of 'security_activity_bloc.dart';

enum SecurityActivityStatus {
  /// The first page is being loaded.
  loading,

  /// The activity is shown, or there is none.
  ready,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class SecurityActivityState extends Equatable {
  const new({
    this.status = SecurityActivityStatus.loading,
    this.events = const [],
    this.next,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final SecurityActivityStatus status;

  /// The entries loaded so far, newest first, as the server sent them.
  final List<SecurityEvent> events;

  /// What the server gave to ask for the next page, or `null` on the last.
  final String? next;

  /// Whether the next page is being loaded.
  final bool loadingMore;

  /// Whether the next page could not be loaded.
  final bool loadMoreFailed;

  /// The entries to show: the imports of one action put together.
  List<SecurityEvent> get entries => groupImports(events);

  SecurityActivityState copyWith({
    SecurityActivityStatus? status,
    List<SecurityEvent>? events,
    String? next,
    bool clearNext = false,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) {
    return SecurityActivityState(
      status: status ?? this.status,
      events: events ?? this.events,
      next: clearNext ? null : next ?? this.next,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    events,
    next,
    loadingMore,
    loadMoreFailed,
  ];
}
