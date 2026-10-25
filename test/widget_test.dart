import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yeogibwayong/core/theme.dart';
import 'package:yeogibwayong/providers/timer_provider.dart';
import 'package:yeogibwayong/screens/timer/timer_screen.dart';
import 'package:yeogibwayong/screens/permission_guide/permission_guide_screen.dart';
import 'timer_provider_test.dart' show MemoryTimerRepository;

void main() {
  for (final size in [const Size(375, 667), const Size(667, 375)]) {
    testWidgets('timer start/pause/resume fits $size at large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final provider = TimerProvider(
        repository: MemoryTimerRepository(),
        scheduleNotification: (_) async {},
        cancelNotification: () async {},
        showPet: (_) async {},
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const TimerScreen(),
          ),
        ),
      );
      expect(find.text('타이머 시작'), findsOneWidget);
      await tester.ensureVisible(find.text('타이머 시작'));
      await tester.tap(find.text('타이머 시작'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('25분 시작'));
      await tester.tap(find.text('25분 시작'));
      await tester.pumpAndSettle();
      expect(find.text('일시 정지'), findsOneWidget);
      expect(tester.takeException(), null);
      await tester.ensureVisible(find.text('일시 정지'));
      await tester.tap(find.text('일시 정지'));
      await tester.pumpAndSettle();
      expect(find.text('재개'), findsOneWidget);
      await tester.ensureVisible(find.text('재개'));
      await tester.tap(find.text('재개'));
      await tester.pumpAndSettle();
      expect(provider.isRunning, true);
      await tester.pumpWidget(const SizedBox());
      provider.dispose();
    });
  }
  testWidgets('permission guide refreshes after request without reopening', (
    tester,
  ) async {
    var granted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionGuideScreen(
          type: PermissionType.usage,
          checkPermission: () async => granted,
          onRequest: () async {
            granted = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정 열기'));
    await tester.pumpAndSettle();
    expect(find.text('허용됨'), findsOneWidget);
    expect(find.text('설정 열기'), findsNothing);
  });
}
