import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/auth/presentation/change_password_screen.dart';
import 'package:money_scribe/features/sessions/data/fake/fake_sessions_repository.dart';
import 'package:money_scribe/features/sessions/domain/device_session.dart';
import 'package:money_scribe/features/sessions/domain/security_event.dart';
import 'package:money_scribe/features/sessions/presentation/security_activity_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/open_screen.dart';
import '../../../support/open_sessions.dart';

/// The fake sessions whose activity answers when the test says so.
class _PendingRepository extends FakeSessionsRepository {
  new({required super.demo, required this.answer});

  final Future<SecurityEventsPage> answer;

  @override
  Future<SecurityEventsPage> activity({String? cursor}) => answer;
}

/// The fake sessions with the activity a test brings.
class _ActivityRepository extends FakeSessionsRepository {
  new({required super.demo, required this.events});

  final List<SecurityEvent> events;

  @override
  Future<SecurityEventsPage> activity({String? cursor}) async {
    return SecurityEventsPage(items: events);
  }
}

void main() {
  group('opening it from the Settings', () {
    testWidgets('has its row in the Security section', (tester) async {
      await openSettings(tester);

      await tester.tap(find.text('Security activity'));
      await tester.pumpAndSettle();

      expect(find.byType(SecurityActivityScreen), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsNothing);
    });
  });

  group('the timeline (ST-13)', () {
    testWidgets('has the title and a back arrow', (tester) async {
      await openSecurityActivity(tester);

      expect(find.widgetWithText(AppBar, 'Security activity'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('puts each entry under the day it happened, newest first', (
      tester,
    ) async {
      await openSecurityActivity(tester);

      for (final day in [
        '25 Oct 2026',
        '20 Oct 2026',
        '14 Oct 2026',
        '13 Oct 2026',
        '12 Oct 2026',
      ]) {
        expect(find.text(day), findsOneWidget, reason: day);
      }
      expect(
        tester.getTopLeft(find.text('25 Oct 2026')).dy,
        lessThan(tester.getTopLeft(find.text('12 Oct 2026')).dy),
      );
    });

    testWidgets('says what happened, to which device, and when', (
      tester,
    ) async {
      await openSecurityActivity(tester);

      expect(find.text('Data exported'), findsOneWidget);
      expect(find.text('Transactions · 125 rows · Pixel 8'), findsOneWidget);
      expect(find.text('18:45'), findsOneWidget);
      expect(find.text('Pixel 8 · Fingerprint'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('Password changed'), findsOneWidget);
      expect(find.text('Chrome on Windows · Password'), findsOneWidget);
    });

    testWidgets('shows how long the activity is kept', (tester) async {
      await openSecurityActivity(tester);

      expect(find.text('Activity is kept for 90 days.'), findsOneWidget);
    });

    testWidgets(
      'an old sign-in used again is a warning that leads to the password',
      (tester) async {
        await openSecurityActivity(tester);

        expect(find.text('Possible reuse of an old sign-in'), findsOneWidget);
        expect(
          find.text(
            'We ended that session to protect your account. '
            'If this was not you, change your password.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.widgetWithText(TextButton, 'Change password'));
        await tester.pumpAndSettle();

        expect(find.byType(ChangePasswordScreen), findsOneWidget);
      },
    );
  });

  group('imports put together', () {
    testWidgets('one import of many calls is one entry', (tester) async {
      final noon = DateTime(2026, 10, 20, 12);
      await openSecurityActivity(
        tester,
        sessionsRepository: (demo) => _ActivityRepository(
          demo: demo,
          events: [
            SecurityEvent(
              id: '2',
              type: SecurityEventType.dataImported,
              occurredAt: noon.add(const Duration(minutes: 3)),
              deviceName: 'Pixel 8',
              sessionId: 's',
              kinds: const ['debts'],
              count: 20,
            ),
            SecurityEvent(
              id: '1',
              type: SecurityEventType.dataImported,
              occurredAt: noon,
              deviceName: 'Pixel 8',
              sessionId: 's',
              kinds: const ['transactions'],
              count: 500,
            ),
          ],
        ),
      );

      expect(find.text('Data imported'), findsOneWidget);
      expect(
        find.text('Debts, Transactions · 520 rows · Pixel 8'),
        findsOneWidget,
      );
    });
  });

  group('generic wording', () {
    testWidgets('a type and a kind the app does not know are still shown', (
      tester,
    ) async {
      await openSecurityActivity(
        tester,
        sessionsRepository: (demo) => _ActivityRepository(
          demo: demo,
          events: [
            SecurityEvent(
              id: '1',
              type: SecurityEventType.unknown,
              occurredAt: DateTime(2026, 10, 20, 12),
              deviceName: 'Pixel 8',
              platform: SessionPlatform.unknown,
            ),
            SecurityEvent(
              id: '2',
              type: SecurityEventType.dataExported,
              occurredAt: DateTime(2026, 10, 19, 12),
              kinds: const ['budgets'],
              count: 1,
            ),
          ],
        ),
      );

      expect(find.text('Account activity'), findsOneWidget);
      expect(find.text('budgets · 1 row'), findsOneWidget);
    });

    testWidgets('every kind of entry has its words', (tester) async {
      await openSecurityActivity(
        tester,
        sessionsRepository: (demo) => _ActivityRepository(
          demo: demo,
          events: [
            for (final (i, type) in SecurityEventType.values.indexed)
              SecurityEvent(
                id: '$i',
                type: type,
                occurredAt: DateTime(2026, 10, 20, 12, i),
                deviceName: 'Pixel 8',
              ),
          ],
        ),
      );

      for (final title in [
        'Signed in',
        'Signed out',
        'Session ended',
        'Signed out: too many devices',
        'Password changed',
        'Password reset',
        'Email changed',
        'Fingerprint sign-in turned on',
        'Fingerprint sign-in turned off',
        'Possible reuse of an old sign-in',
        'Data exported',
        'Data imported',
        'Account activity',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
    });
  });

  group('the next page', () {
    testWidgets('Show more adds it', (tester) async {
      await openSecurityActivity(
        tester,
        sessionsRepository: (demo) =>
            FakeSessionsRepository(demo: demo, pageSize: 3),
      );
      expect(find.text('Signed in'), findsOneWidget);
      expect(find.text('12 Oct 2026'), findsNothing);

      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      expect(find.text('12 Oct 2026'), findsOneWidget);
      expect(find.text('Show more'), findsNothing);
    });
  });

  group('loading, empty, error and no connection (ST-14)', () {
    testWidgets('shows grey blocks while the activity loads', (tester) async {
      final pending = Completer<SecurityEventsPage>();
      await openSecurityActivity(
        tester,
        sessionsRepository: (demo) =>
            _PendingRepository(demo: demo, answer: pending.future),
      );

      expect(find.byType(SkeletonBox), findsWidgets);

      pending.complete(const SecurityEventsPage(items: []));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('says when there is no activity yet', (tester) async {
      await openSecurityActivity(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text('No activity yet'), findsOneWidget);
    });

    testWidgets('an error offers Try again', (tester) async {
      await openSecurityActivity(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.error),
      );
      expect(find.text("Couldn't load your activity"), findsOneWidget);
    });

    testWidgets('no connection offers Try again', (tester) async {
      await openSecurityActivity(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );
      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels and Western digits', (tester) async {
      await openSecurityActivity(tester, language: AppLanguage.arabic);

      expect(find.text('نشاط الأمان'), findsWidgets);
      expect(find.text('تم تصدير البيانات'), findsOneWidget);
      expect(find.text('18:45'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
    });
  });

  group('large text', () {
    testWidgets('fits at 200%', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await openSecurityActivity(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
