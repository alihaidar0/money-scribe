import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/features/auth/domain/password_problem.dart';

/// The words for a password the server refused, in the language of the app.
/// The limit in the message comes from the server, so a change of the policy
/// needs no new version of the app. A reason the app does not know shows the
/// server's own English text as it is.
String passwordProblemText(AppLocalizations l10n, PasswordProblem problem) {
  final limit = problem.limit;
  return switch (problem.issue) {
    PasswordIssue.tooShort =>
      limit == null
          ? l10n.passwordErrorTooShort
          : l10n.passwordErrorTooShortLimit(count: limit),
    PasswordIssue.tooLong =>
      limit == null
          ? l10n.passwordErrorTooLong
          : l10n.passwordErrorTooLongLimit(count: limit),
    PasswordIssue.tooSimilar => l10n.passwordErrorTooSimilar,
    PasswordIssue.tooCommon => l10n.passwordErrorTooCommon,
    PasswordIssue.compromised => l10n.passwordErrorCompromised,
    PasswordIssue.unchanged => l10n.passwordErrorUnchanged,
    PasswordIssue.other => problem.detail ?? l10n.passwordErrorRejected,
  };
}
