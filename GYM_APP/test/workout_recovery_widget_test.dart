import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:gym_app/core/localization/app_translations.dart';
import 'package:gym_app/core/localization/locale_controller.dart';
import 'package:gym_app/core/services/api_client.dart';
import 'package:gym_app/features/exercises/models/exercise.dart';
import 'package:gym_app/features/workout/models/logged_set.dart';
import 'package:gym_app/features/workout/models/session_exercise.dart';
import 'package:gym_app/features/workout/services/pending_set_store.dart';
import 'package:gym_app/features/workout/widgets/exercise_logging_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final locale in [LocaleController.english, LocaleController.arabic]) {
    testWidgets(
      'restores and retries without duplicating a resumed row: $locale',
      (tester) async {
        FlutterSecureStorage.setMockInitialValues({'auth_token': 'test'});
        Get.put(LocaleController()).locale.value = locale;
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(Get.reset);

        final saved = LoggedSet(
          id: 123,
          sessionExerciseId: 20,
          setNumber: 1,
          reps: 10,
          weight: 60,
          weightUnit: 'kg',
        );
        await PendingSetStore().save(1, saved);
        var count = 0;
        final busy = <bool>[];
        final interceptor = InterceptorsWrapper(
          onRequest: (request, handler) {
            if (request.method == 'GET') {
              // The previous-performance lookup must not break recovery offline.
              handler.reject(
                DioException(
                  requestOptions: request,
                  type: DioExceptionType.connectionError,
                ),
              );
            } else {
              expect(request.data, saved.toJson());
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {...saved.toJson(), 'id': 123},
                  statusCode: 201,
                ),
              );
            }
          },
        );
        ApiClient.instance.dio.interceptors.add(interceptor);
        addTearDown(
          () => ApiClient.instance.dio.interceptors.remove(interceptor),
        );
        await tester.pumpWidget(
          GetMaterialApp(
            locale: locale,
            translations: AppTranslations(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: Scaffold(
              body: ExerciseLoggingPage(
                sessionId: 1,
                sessionExercise: const SessionExercise(
                  id: 20,
                  exerciseId: 2,
                  order: 1,
                ),
                exercise: const Exercise(
                  id: 2,
                  muscleGroupId: 1,
                  nameEn: 'Bench press',
                  nameAr: 'ضغط بنش',
                ),
                initialSets: [saved],
                onSavingChanged: busy.add,
                onSetLogged: (_, total) => count = total,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('set_waiting_sync'.tr), findsOneWidget);
        final retry = find.text('retry_set_sync'.tr);
        await tester.ensureVisible(retry);
        await tester.tap(retry);
        await tester.pumpAndSettle();
        expect(count, 1);
        expect(busy, [true, false]);
        expect(find.text('set_waiting_sync'.tr), findsNothing);
        expect(find.text('${'set_label'.tr} 2'), findsOneWidget);
        expect(await PendingSetStore().hasPending(1), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
