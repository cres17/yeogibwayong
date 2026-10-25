import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeogibwayong/core/theme.dart';
import 'package:yeogibwayong/data/repositories/pet_repository.dart';
import 'package:yeogibwayong/data/repositories/settings_repository.dart';
import 'package:yeogibwayong/data/repositories/usage_repository.dart';
import 'package:yeogibwayong/providers/pet_provider.dart';
import 'package:yeogibwayong/providers/settings_provider.dart';
import 'package:yeogibwayong/providers/timer_provider.dart';
import 'package:yeogibwayong/providers/usage_provider.dart';
import 'package:yeogibwayong/screens/shell/main_shell.dart';
import 'timer_provider_test.dart' show MemoryTimerRepository;

class EmptyUsageRepository extends UsageRepository {
  @override
  Future<List<Map<String, dynamic>>> getDailyUsageAll(
    String dateString,
  ) async => [];
  @override
  Future<List<Map<String, dynamic>>> getWeeklyTotals({
    required String fromDate,
    required String toDate,
  }) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in [
      'dev.fluttercommunity.plus/sensors/method',
      'dev.fluttercommunity.plus/sensors/accelerometer',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.cres.yeogibwayong/apps'),
      (_) async => [],
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('usage_stats'),
      (_) async => false,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('x-slayer/overlay_channel'),
      (_) async => false,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (_) async => 0,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (_) async => {
        'appName': '여기봐용',
        'packageName': 'com.cres.yeogibwayong',
        'version': '1.0.0',
        'buildNumber': '1',
      },
    );
  });
  for (final scenario in [
    (size: const Size(320, 640), scale: 1.0),
    (size: const Size(375, 667), scale: 1.5),
  ]) {
    testWidgets(
      'all tabs fit ${scenario.size} at text scale ${scenario.scale}',
      (tester) async {
        tester.view.physicalSize = scenario.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final settings = SettingsRepository();
        final timer = TimerProvider(
          repository: MemoryTimerRepository(),
          scheduleNotification: (_) async {},
          cancelNotification: () async {},
          showPet: (_) async {},
        );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => PetProvider(PetRepository(), settings),
              ),
              ChangeNotifierProvider(create: (_) => SettingsProvider(settings)),
              ChangeNotifierProvider(
                create: (_) => UsageProvider(EmptyUsageRepository()),
              ),
              ChangeNotifierProvider.value(value: timer),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scenario.scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const MainShell(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        for (final label in ['제한', '놀이터', '통계', '설정', '홈']) {
          await tester.tap(find.widgetWithText(NavigationDestination, label));
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            tester.takeException(),
            isNull,
            reason: 'after opening $label',
          );
        }
        await tester.pumpWidget(const SizedBox());
        timer.dispose();
      },
    );
  }
}
