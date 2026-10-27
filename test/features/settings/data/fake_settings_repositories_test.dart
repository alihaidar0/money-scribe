import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/settings/data/fake/fake_csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/data/fake/fake_default_currency_repository.dart';
import 'package:money_scribe/features/settings/data/fake/fake_pay_schedule_repository.dart';
import 'package:money_scribe/features/settings/data/shared_preferences_theme_repository.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';
import 'package:money_scribe/features/settings/domain/pay_schedule.dart';
import 'package:money_scribe/features/settings/domain/theme_choice.dart';

import '../../../support/in_memory_preferences.dart';

void main() {
  late DemoController demo;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
  });

  group('pay schedule', () {
    test('is the default before one is saved', () async {
      final repository = FakePayScheduleRepository(demo: demo);

      expect(await repository.load(), const PaySchedule());
    });

    test('is what was saved, and the mode follows the demo panel', () async {
      final repository = FakePayScheduleRepository(demo: demo);
      await repository.save(
        const PaySchedule(
          mode: PaymentMode.twoPayments,
          firstPayDay: 17,
          remindOnPayDays: true,
        ),
      );

      demo.update(const DemoSettings());

      final schedule = await repository.load();
      expect(schedule.mode, PaymentMode.onePayment);
      expect(schedule.firstPayDay, 17);
      expect(schedule.remindOnPayDays, isTrue);
    });

    test('saving the mode changes how the account is paid', () async {
      final repository = FakePayScheduleRepository(demo: demo);

      await repository.save(const PaySchedule(mode: PaymentMode.twoPayments));

      expect(demo.settings.paymentMode, PaymentMode.twoPayments);
    });
  });

  group('default currency', () {
    test('is the ruble until another is saved', () async {
      final repository = FakeDefaultCurrencyRepository(demo: demo);

      expect(await repository.load(), Currency.rub);

      await repository.save(Currency.usd);

      expect(await repository.load(), Currency.usd);
    });

    test('does not save when the panel says saving fails', () async {
      final repository = FakeDefaultCurrencyRepository(demo: demo);
      demo.update(const DemoSettings(save: DemoSave.fails));

      await expectLater(
        repository.save(Currency.usd),
        throwsA(isA<NoConnectionException>()),
      );
      demo.update(const DemoSettings());
      expect(await repository.load(), Currency.rub);
    });
  });

  group('csv transfer', () {
    test(
      'the picker offers the sample files, then one it cannot read',
      () async {
        final repository = FakeCsvTransferRepository(demo: demo);

        expect(
          await repository.chooseFile(),
          FakeCsvTransferRepository.files[0],
        );
        expect(
          await repository.chooseFile(),
          FakeCsvTransferRepository.files[1],
        );
        expect(
          await repository.chooseFile(),
          FakeCsvTransferRepository.files[2],
        );
        await expectLater(
          repository.chooseFile(),
          throwsA(
            isA<CsvFileException>().having(
              (error) => error.issue,
              'issue',
              CsvFileIssue.unknownColumns,
            ),
          ),
        );
        expect(
          await repository.chooseFile(),
          FakeCsvTransferRepository.files[0],
        );
      },
    );

    test(
      'the check of the first file finds nothing, the import four',
      () async {
        final repository = FakeCsvTransferRepository(demo: demo);
        final file = FakeCsvTransferRepository.files.first;
        final progress = <int>[];

        final estimate = await repository.check(file);
        final result = await repository.import(file, onProgress: progress.add);

        expect(estimate, const CsvImportResult(imported: 42));
        expect(result.imported, 38);
        expect(result.problems, FakeCsvTransferRepository.problems);
        expect(progress, [42]);
      },
    );

    test(
      'the export of several kinds skips an account and a category',
      () async {
        final repository = FakeCsvTransferRepository(demo: demo);
        final file = FakeCsvTransferRepository.files[2];

        final result = await repository.import(file);

        expect(file.parts.map((part) => part.kind), [
          CsvDataKind.accounts,
          CsvDataKind.categories,
          CsvDataKind.transactions,
        ]);
        expect(result.imported, 23);
        expect(result.problems, FakeCsvTransferRepository.zipProblems);
      },
    );

    test('remembers what was exported last', () async {
      final repository = FakeCsvTransferRepository(demo: demo);
      const request = CsvExportRequest(
        kinds: {CsvDataKind.debts},
        period: CsvPeriod.allTime,
      );

      await repository.export(request, password: 'secret');

      expect(repository.lastExport, request);
    });

    test('the demo refuses the password, or locks the export', () async {
      final repository = FakeCsvTransferRepository(demo: demo);
      const request = CsvExportRequest(
        kinds: {CsvDataKind.debts},
        period: CsvPeriod.allTime,
      );

      demo.update(const DemoSettings(signIn: DemoSignIn.wrongPassword));
      await expectLater(
        repository.export(request, password: 'x'),
        throwsA(isA<CsvExportRefusedException>()),
      );
      demo.update(
        const DemoSettings(passwordChange: DemoPasswordChange.locked),
      );
      await expectLater(
        repository.export(request, password: 'x'),
        throwsA(isA<TooManyRequestsException>()),
      );
      expect(repository.lastExport, isNull);
    });
  });

  group('theme', () {
    test('nothing saved follows the system', () async {
      final repository = SharedPreferencesThemeRepository(
        await openInMemoryPreferences(),
      );

      expect(repository.read(), ThemeChoice.system);
    });

    test('a saved theme is read back', () async {
      final repository = SharedPreferencesThemeRepository(
        await openInMemoryPreferences(),
      );

      await repository.write(ThemeChoice.dark);

      expect(repository.read(), ThemeChoice.dark);
    });

    test('choosing the system theme clears the saved one', () async {
      final preferences = await openInMemoryPreferences({
        SharedPreferencesThemeRepository.storageKey: 'dark',
      });
      final repository = SharedPreferencesThemeRepository(preferences);

      await repository.write(ThemeChoice.system);

      expect(
        preferences.containsKey(SharedPreferencesThemeRepository.storageKey),
        isFalse,
      );
      expect(repository.read(), ThemeChoice.system);
    });

    test('an unknown stored name follows the system', () {
      expect(ThemeChoice.fromName('purple'), ThemeChoice.system);
      expect(ThemeChoice.fromName(null), ThemeChoice.system);
    });
  });
}
