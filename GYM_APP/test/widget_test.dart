import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/workout/models/logged_set.dart';
import 'package:gym_app/features/workout/services/pending_set_store.dart';
import 'package:gym_app/features/workout/services/workout_service.dart';

LoggedSet draft({int reps = 10}) => LoggedSet(
  sessionExerciseId: 20,
  setNumber: 1,
  reps: reps,
  weight: 60,
  weightUnit: 'kg',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'lost response survives reopening and retry uses original ID and values',
    () async {
      final dio = Dio();
      Map<String, dynamic>? first;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            first = Map<String, dynamic>.from(request.data as Map);
            handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.receiveTimeout,
              ),
            );
          },
        ),
      );
      await expectLater(
        WorkoutService(dio: dio).logSet(1, draft()),
        throwsA(isA<DioException>()),
      );
      final restored = await PendingSetStore().read(1, 20);
      expect(restored!.reps, 10);
      expect(restored.clientRequestId, first!['client_request_id']);
      expect(await PendingSetStore().read(2, 20), isNull);

      final retryDio = Dio();
      retryDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            expect(request.data, first);
            handler.resolve(
              Response(
                requestOptions: request,
                data: {...first!, 'id': 123},
                statusCode: 201,
              ),
            );
          },
        ),
      );
      // Even an accidentally changed draft must not overwrite an uncertain save.
      final saved = await WorkoutService(
        dio: retryDio,
      ).logSet(1, draft(reps: 99));
      expect(saved.id, 123);
      expect(saved.reps, 10);
      expect(await PendingSetStore().hasPending(1), isFalse);
    },
  );

  test(
    'overlapping retries share one request even across service instances',
    () async {
      final dio = Dio();
      final requested = Completer<void>();
      final response = Completer<void>();
      var requests = 0;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            requests++;
            requested.complete();
            await response.future;
            handler.resolve(
              Response(
                requestOptions: request,
                data: {...(request.data as Map), 'id': 123},
                statusCode: 201,
              ),
            );
          },
        ),
      );
      final first = WorkoutService(dio: dio).logSet(1, draft());
      await requested.future;
      final second = WorkoutService(dio: dio).logSet(1, draft());
      response.complete();
      final saved = await Future.wait([first, second]);
      expect(requests, 1);
      expect(saved.map((set) => set.id), [123, 123]);
      expect(await PendingSetStore().hasPending(1), isFalse);
    },
  );

  test('journal exists before the network request is sent', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) async {
          final pending = await PendingSetStore().read(1, 20);
          expect(pending!.toJson(), request.data);
          handler.resolve(
            Response(
              requestOptions: request,
              data: {...pending.toJson(), 'id': 123},
              statusCode: 201,
            ),
          );
        },
      ),
    );
    await WorkoutService(dio: dio).logSet(1, draft());
  });

  test('validation rejection allows correcting the draft', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.reject(
            DioException(
              requestOptions: request,
              response: Response(requestOptions: request, statusCode: 422),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );
    await expectLater(
      WorkoutService(dio: dio).logSet(1, draft()),
      throwsA(isA<DioException>()),
    );
    expect(await PendingSetStore().hasPending(1), isFalse);
  });

  test('server failure retains pending save', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.reject(
            DioException(
              requestOptions: request,
              response: Response(requestOptions: request, statusCode: 500),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );
    await expectLater(
      WorkoutService(dio: dio).logSet(1, draft()),
      throwsA(isA<DioException>()),
    );
    expect(await PendingSetStore().hasPending(1), isTrue);
  });

  test(
    'finish never reaches the server while this session has pending sets',
    () async {
      final store = PendingSetStore();
      await store.save(1, draft());
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (_, __) {
            fail('Must not finish a workout with pending sets');
          },
        ),
      );
      await expectLater(
        WorkoutService(dio: dio).finishSession(1),
        throwsA(isA<PendingWorkoutSetsException>()),
      );
      expect(await store.hasPending(2), isFalse);
    },
  );
}
