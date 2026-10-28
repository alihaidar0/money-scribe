import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/settings/bloc/csv_export_password_bloc.dart';
import 'package:money_scribe/features/settings/data/fake/fake_csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

import '../../../support/fake_ticker.dart';

/// Answers `export` the way a test says, and notes the password it got.
class _Repository extends FakeCsvTransferRepository {
  new({required super.demo, this.error});

  final Exception? error;
  String? password;

  @override
  Future<void> export(
    CsvExportRequest request, {
    required String password,
  }) async {
    this.password = password;
    final error = this.error;
    if (error != null) throw error;
    await super.export(request, password: password);
  }
}

void main() {
  late DemoController demo;
  late FakeTicker ticker;
  late _Repository repository;

  const request = CsvExportRequest(
    kinds: {CsvDataKind.transactions},
    period: CsvPeriod.allTime,
  );

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    ticker = FakeTicker();
    repository = _Repository(demo: demo);
  });

  CsvExportPasswordBloc build() => CsvExportPasswordBloc(
    repository: repository,
    ticker: ticker,
    request: request,
  );

  CsvExportPasswordBloc failing(Exception error) {
    repository = _Repository(demo: demo, error: error);
    return build();
  }

  blocTest<CsvExportPasswordBloc, CsvExportPasswordState>(
    'exports with the password exactly as typed',
    build: build,
    act: (bloc) => bloc
      ..add(const CsvExportPasswordEdited(' secret '))
      ..add(const CsvExportPasswordSubmitted()),
    verify: (bloc) {
      expect(bloc.state.status, CsvExportPasswordStatus.done);
      expect(repository.password, ' secret ');
      expect(repository.lastExport, request);
    },
  );

  blocTest<CsvExportPasswordBloc, CsvExportPasswordState>(
    'sends nothing while the password is empty',
    build: build,
    act: (bloc) => bloc.add(const CsvExportPasswordSubmitted()),
    expect: () => const <CsvExportPasswordState>[],
    verify: (_) => expect(repository.password, isNull),
  );

  blocTest<CsvExportPasswordBloc, CsvExportPasswordState>(
    'says a wrong password, and typing again clears it',
    build: () => failing(const CsvExportRefusedException()),
    act: (bloc) async {
      bloc
        ..add(const CsvExportPasswordEdited('wrong'))
        ..add(const CsvExportPasswordSubmitted());
      await bloc.stream.firstWhere(
        (s) => s.status == CsvExportPasswordStatus.wrongPassword,
      );
      bloc.add(const CsvExportPasswordEdited('wrong2'));
    },
    verify: (bloc) {
      expect(bloc.state.status, CsvExportPasswordStatus.editing);
      expect(bloc.state.password, 'wrong2');
    },
  );

  test('too many attempts lock it with the countdown of the server', () async {
    final bloc = failing(const TooManyRequestsException(Duration(minutes: 15)));
    addTearDown(bloc.close);

    bloc
      ..add(const CsvExportPasswordEdited('wrong'))
      ..add(const CsvExportPasswordSubmitted());
    await bloc.stream.firstWhere(
      (s) => s.status == CsvExportPasswordStatus.waiting,
    );

    expect(bloc.state.waitSecondsLeft, 900);
    expect(ticker.started, [900]);

    // Typing does not end the wait, and nothing is sent meanwhile.
    bloc
      ..add(const CsvExportPasswordEdited('again'))
      ..add(const CsvExportPasswordSubmitted());
    ticker.tick(872);
    await pumpEventQueue();
    expect(bloc.state.status, CsvExportPasswordStatus.waiting);
    expect(bloc.state.waitSecondsLeft, 872);
    expect(repository.password, 'wrong');

    ticker.tick(0);
    await pumpEventQueue();
    expect(bloc.state.status, CsvExportPasswordStatus.editing);
    expect(bloc.state.password, 'again');
  });

  for (final (error, status) in [
    (const ServiceUnavailableException(), CsvExportPasswordStatus.unavailable),
    (const NoConnectionException(), CsvExportPasswordStatus.noConnection),
    (const ServerException(), CsvExportPasswordStatus.failure),
  ]) {
    blocTest<CsvExportPasswordBloc, CsvExportPasswordState>(
      '${error.runtimeType} is ${status.name}',
      build: () => failing(error),
      act: (bloc) => bloc
        ..add(const CsvExportPasswordEdited('secret'))
        ..add(const CsvExportPasswordSubmitted()),
      errors: () => [if (status == CsvExportPasswordStatus.failure) error],
      verify: (bloc) => expect(bloc.state.status, status),
    );
  }
}
