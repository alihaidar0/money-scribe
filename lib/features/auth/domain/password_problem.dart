import 'package:equatable/equatable.dart';

/// Why the server refused a password. The server owns the password policy, so
/// the app only knows the reasons and words them; it never checks a rule
/// itself.
enum PasswordIssue {
  /// Shorter than the server accepts: [PasswordProblem.limit] is the minimum.
  tooShort,

  /// Longer than the server accepts: [PasswordProblem.limit] is the maximum.
  tooLong,

  /// Too much like the name or the email.
  tooSimilar,

  /// One of the most common passwords.
  tooCommon,

  /// Found in a known data breach.
  compromised,

  /// The same as the current password (changing a password).
  unchanged,

  /// A reason this version of the app does not know: show
  /// [PasswordProblem.detail], the server's own English text.
  other,
}

/// One refusal of a password, with what the message needs.
final class PasswordProblem extends Equatable {
  const new(this.issue, {this.limit, this.detail});

  final PasswordIssue issue;

  /// The length the server asked for, when it said so: `min_length` for
  /// [PasswordIssue.tooShort], `max_length` for [PasswordIssue.tooLong].
  final int? limit;

  /// The server's English text, for [PasswordIssue.other].
  final String? detail;

  @override
  List<Object?> get props => [issue, limit, detail];
}
