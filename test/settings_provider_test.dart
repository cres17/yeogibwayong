import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeogibwayong/providers/settings_provider.dart';
import 'package:yeogibwayong/data/repositories/settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('missing usage permission cannot enable monitoring', () async {
    var starts = 0;
    final repo = SettingsRepository();
    final settings = SettingsProvider(
      repo,
      hasUsagePermission: () async => false,
      hasOverlayPermission: () async => true,
      startService: () async {
        starts++;
      },
      stopService: () async {},
    );
    await settings.setUsageTrackingEnabled(true);
    expect(starts, 0);
    expect(settings.usageTrackingEnabled, false);
    expect(await repo.getUsageTrackingEnabled(), false);
    expect(settings.trackingError, isNotNull);
    settings.dispose();
  });
  test('missing overlay permission cannot enable monitoring', () async {
    final settings = SettingsProvider(
      SettingsRepository(),
      hasUsagePermission: () async => true,
      hasOverlayPermission: () async => false,
      startService: () async => fail('must not start'),
      stopService: () async {},
    );
    await settings.setUsageTrackingEnabled(true);
    expect(settings.usageTrackingEnabled, false);
    settings.dispose();
  });
  test('service failure rolls back persisted enabled state', () async {
    final repo = SettingsRepository();
    final settings = SettingsProvider(
      repo,
      hasUsagePermission: () async => true,
      hasOverlayPermission: () async => true,
      startService: () async {
        throw StateError('denied');
      },
      stopService: () async {},
    );
    await settings.setUsageTrackingEnabled(true);
    expect(settings.usageTrackingEnabled, false);
    expect(await repo.getUsageTrackingEnabled(), false);
    expect(settings.trackingBusy, false);
    settings.dispose();
  });
  test(
    'successful start observes persisted consent; disabling persists before stop',
    () async {
      final repo = SettingsRepository();
      final settings = SettingsProvider(
        repo,
        hasUsagePermission: () async => true,
        hasOverlayPermission: () async => true,
        startService: () async =>
            expect(await repo.getUsageTrackingEnabled(), true),
        stopService: () async =>
            expect(await repo.getUsageTrackingEnabled(), false),
      );
      await settings.setUsageTrackingEnabled(true);
      expect(settings.usageTrackingEnabled, true);
      await settings.setUsageTrackingEnabled(false);
      expect(settings.usageTrackingEnabled, false);
      settings.dispose();
    },
  );
}
