import 'package:flutter/material.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/money_formatter_context.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';

/// The words of the sessions and the security activity.
extension SessionTexts on AppLocalizations {
  /// Why a session ended. A reason the app does not know is a plain "ended".
  String endReasonText(SessionEndReason? reason) {
    return switch (reason) {
      SessionEndReason.signedOut => sessionEndReasonSignedOut,
      SessionEndReason.revokedByUser => sessionEndReasonRevoked,
      SessionEndReason.expired => sessionEndReasonExpired,
      SessionEndReason.sessionLimit => sessionEndReasonLimit,
      SessionEndReason.passwordChanged => sessionEndReasonPasswordChanged,
      SessionEndReason.passwordReset => sessionEndReasonPasswordReset,
      SessionEndReason.emailChanged => sessionEndReasonEmailChanged,
      SessionEndReason.tokenReuse => sessionEndReasonTokenReuse,
      SessionEndReason.replaced => sessionEndReasonReplaced,
      SessionEndReason.unknown || null => sessionEndReasonUnknown,
    };
  }

  /// How a session signed in, or `null` for a method the app does not know.
  String? signInMethodText(SignInMethod? method) {
    return switch (method) {
      SignInMethod.password => sessionMethodPassword,
      SignInMethod.emailCode => sessionMethodEmailCode,
      SignInMethod.deviceKey => sessionMethodFingerprint,
      SignInMethod.unknown || null => null,
    };
  }

  /// A kind of data of an export or an import. One the app does not know is
  /// shown as the server wrote it.
  String dataKindText(String kind) {
    return switch (kind) {
      'transactions' => securityDataKindTransactions,
      'debts' => securityDataKindDebts,
      'salary_months' => securityDataKindSalaryMonths,
      _ => kind,
    };
  }
}

/// The times of the sessions, in the time of the device.
extension SessionTimes on BuildContext {
  /// A moment with its day and year, such as `22 Oct 2026, 09:30`.
  String sessionMoment(DateTime moment) {
    final local = moment.toLocal();
    final days = dayFormatter;
    return l10n.sessionDayAt(
      date: days.formatWithYear(local),
      time: days.formatTime(local),
    );
  }

  /// A moment as the person says it: `today, 18:40` for today, else the day
  /// and the time, with the year only when it is not this year.
  String sessionRecently(DateTime moment, {required DateTime today}) {
    final local = moment.toLocal();
    final days = dayFormatter;
    if (days.isSameDay(local, today)) {
      return l10n.sessionTodayAt(time: days.formatTime(local));
    }
    return l10n.sessionDayAt(
      date: days.formatDate(local, today: today),
      time: days.formatTime(local),
    );
  }

  /// A day with its year, such as `20 Jan 2027`.
  String sessionDay(DateTime moment) {
    return dayFormatter.formatWithYear(moment.toLocal());
  }

  /// The icon of the device a session came from.
  IconData sessionIcon(SessionPlatform? platform) {
    return switch (platform) {
      SessionPlatform.web => Icons.computer_outlined,
      SessionPlatform.android ||
      SessionPlatform.ios ||
      SessionPlatform.unknown ||
      null => Icons.smartphone,
    };
  }
}

/// How an entry of the security activity is shown.
extension SecurityEventTexts on AppLocalizations {
  String eventTitle(SecurityEventType type) {
    return switch (type) {
      SecurityEventType.signedIn => securityEventSignedIn,
      SecurityEventType.signedOut => securityEventSignedOut,
      SecurityEventType.sessionRevoked => securityEventSessionRevoked,
      SecurityEventType.sessionLimitReached => securityEventSessionLimit,
      SecurityEventType.passwordChanged => securityEventPasswordChanged,
      SecurityEventType.passwordReset => securityEventPasswordReset,
      SecurityEventType.emailChanged => securityEventEmailChanged,
      SecurityEventType.deviceKeyAdded => securityEventKeyAdded,
      SecurityEventType.deviceKeyRemoved => securityEventKeyRemoved,
      SecurityEventType.tokenReuseDetected => securityEventTokenReuse,
      SecurityEventType.dataExported => securityEventDataExported,
      SecurityEventType.dataImported => securityEventDataImported,
      SecurityEventType.unknown => securityEventUnknown,
    };
  }

  /// The facts under the title: the device, and how it signed in or what data
  /// moved. `null` when the entry has none.
  String? eventDetail(SecurityEvent event) {
    final facts = <String>[
      if (event.type == SecurityEventType.dataExported ||
          event.type == SecurityEventType.dataImported) ...[
        if (event.kinds.isNotEmpty) event.kinds.map(dataKindText).join(', '),
        if (event.count != null) csvRowCount(rows: event.count!),
      ],
      if (event.deviceName != null && event.deviceName!.isNotEmpty)
        event.deviceName!,
      ?signInMethodText(
        event.type == SecurityEventType.signedIn ? event.signInMethod : null,
      ),
    ];
    if (facts.isEmpty) return null;
    return facts.reduce(eventDetailJoin);
  }

  /// Two facts of an entry, joined.
  String eventDetailJoin(String first, String second) {
    return securityEventDetail(first: first, second: second);
  }

  IconData eventIcon(SecurityEventType type) {
    return switch (type) {
      SecurityEventType.signedIn => Icons.login,
      SecurityEventType.signedOut => Icons.logout,
      SecurityEventType.sessionRevoked => Icons.phonelink_erase_outlined,
      SecurityEventType.sessionLimitReached => Icons.devices_other_outlined,
      SecurityEventType.passwordChanged ||
      SecurityEventType.passwordReset => Icons.lock_reset,
      SecurityEventType.emailChanged => Icons.alternate_email,
      SecurityEventType.deviceKeyAdded ||
      SecurityEventType.deviceKeyRemoved => Icons.fingerprint,
      SecurityEventType.tokenReuseDetected => Icons.warning_amber_outlined,
      SecurityEventType.dataExported => Icons.file_download_outlined,
      SecurityEventType.dataImported => Icons.file_upload_outlined,
      SecurityEventType.unknown => Icons.info_outline,
    };
  }
}
