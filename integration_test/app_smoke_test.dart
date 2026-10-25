import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:yeogibwayong/main.dart' as app;
import 'package:yeogibwayong/data/database/database_service.dart';
import 'package:yeogibwayong/providers/pet_provider.dart';
import 'package:yeogibwayong/providers/timer_provider.dart';
import 'package:yeogibwayong/screens/home/home_screen.dart';
import 'package:yeogibwayong/services/installed_apps_service.dart';
import 'package:yeogibwayong/services/overlay_service.dart';

// Overlay engines look up their entrypoint in the test's root library.
@pragma('vm:entry-point')
void overlayMain() => app.overlayMain();

Future<void> waitFor(
  WidgetTester tester,
  bool Function() ready,
  String label,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 30));
  while (!ready() && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  if (!ready()) debugDumpApp();
  expect(ready(), isTrue, reason: 'Timed out waiting for $label');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('launch, native app list, SQLite timer and pet overlay', (
    tester,
  ) async {
    await app.main();
    await waitFor(
      tester,
      () =>
          find.text('나중에 설정할게요').evaluate().isNotEmpty ||
          find.byType(HomeScreen).evaluate().isNotEmpty,
      'onboarding or home',
    );
    final skip = find.text('나중에 설정할게요');
    if (skip.evaluate().isNotEmpty) {
      await tester.ensureVisible(skip);
      await tester.tap(skip);
    }
    await waitFor(
      tester,
      () => find.byType(HomeScreen).evaluate().isNotEmpty,
      'home',
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    final apps = await InstalledAppsService.getInstalledApplications();
    expect(apps, isNotEmpty);
    expect(
      apps.every((entry) => entry.packageName != 'com.cres.yeogibwayong'),
      isTrue,
    );
    final context = tester.element(find.byType(HomeScreen));
    final timer = context.read<TimerProvider>();
    await timer.start(60);
    await timer.pause();
    expect(timer.isPaused, isTrue);
    final db = await DatabaseService.instance.database;
    expect(await db.query('active_timer'), hasLength(1));
    await timer.resume();
    await timer.cancel();
    expect(await db.query('active_timer'), isEmpty);
    expect((await db.query('timer_sessions')).last['was_interrupted'], 1);
    await waitFor(
      tester,
      () => context.read<PetProvider>().activePet != null,
      'default pet',
    );
    final pet = context.read<PetProvider>().activePet!;
    expect(await OverlayService.instance.isPermissionGranted(), isTrue);
    await OverlayService.instance.show(
      petImagePath: pet.imagePath,
      triggerType: 'preview',
    );
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(await FlutterOverlayWindow.isActive(), isTrue);
    await OverlayService.instance.close();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    // Leave the home screen visible for the CI screenshot.
  });
}
