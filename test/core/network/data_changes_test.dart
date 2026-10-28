import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/network/data_changes.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  late DataChanges changes;
  late Dio dio;
  late int announced;

  setUp(() {
    changes = DataChanges();
    announced = 0;
    changes.stream.listen((_) => announced++);
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeHttpAdapter((options) => jsonBody(200))
      ..interceptors.add(DataChangesInterceptor(changes));
  });

  tearDown(() => changes.dispose());

  test('announces a change after a write the server accepted', () async {
    await dio.post<void>('/x', data: {'a': 1});
    await dio.patch<void>('/x');
    await dio.delete<void>('/x');
    await pumpEventQueue();

    expect(announced, 3);
  });

  test('does not announce a read', () async {
    await dio.get<void>('/x');
    await dio.head<void>('/x');
    await pumpEventQueue();

    expect(announced, 0);
  });

  test('does not announce a write the server refused', () async {
    final refusing = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = FakeHttpAdapter((options) => jsonBody(400))
      ..interceptors.add(DataChangesInterceptor(changes));

    await expectLater(refusing.post<void>('/x'), throwsA(isA<DioException>()));
    await pumpEventQueue();

    expect(announced, 0);
  });
}
