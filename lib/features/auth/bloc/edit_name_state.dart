part of 'edit_name_bloc.dart';

enum EditNameStatus {
  /// The person is typing.
  editing,

  /// The name is being saved.
  saving,

  /// The name was saved: see [EditNameState.profile].
  saved,

  /// The server refused the name: see [EditNameState.issue].
  rejected,

  /// The server is busy: try again shortly.
  unavailable,

  /// The server could not be reached.
  noConnection,

  /// The server failed.
  failure,
}

final class EditNameState extends Equatable {
  const new({
    required this.currentName,
    required this.name,
    this.status = EditNameStatus.editing,
    this.issue,
    this.profile,
  });

  /// The name the account has now.
  final String currentName;

  /// The name as typed, never trimmed here.
  final String name;

  final EditNameStatus status;

  /// Why the server refused the name, while [status] is `rejected`.
  final NameIssue? issue;

  /// The profile with the new name, once [status] is `saved`.
  final AccountProfile? profile;

  /// Whether the name can be saved: something is typed besides spaces, and it
  /// is not the name the account already has.
  bool get canSave {
    final trimmed = name.trim();
    return trimmed.isNotEmpty && trimmed != currentName.trim();
  }

  EditNameState copyWith({
    EditNameStatus? status,
    NameIssue? issue,
    AccountProfile? profile,
  }) {
    return EditNameState(
      currentName: currentName,
      name: name,
      status: status ?? this.status,
      // A refusal belongs to the attempt that got it.
      issue: issue,
      profile: profile ?? this.profile,
    );
  }

  @override
  List<Object?> get props => [currentName, name, status, issue, profile];
}
