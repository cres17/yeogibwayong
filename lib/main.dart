import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'overlay/overlay_main.dart' as pet_overlay;

import 'core/constants.dart';
import 'data/models/pet_model.dart';
import 'data/repositories/pet_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/usage_repository.dart';
import 'providers/app_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/timer_provider.dart';
import 'providers/usage_provider.dart';
import 'services/asset_copy_service.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';

// The Android plugin resolves this symbol in the root Dart library.
@pragma('vm:entry-point')
void overlayMain() => pet_overlay.overlayMain();

// WorkManager callback — runs in its own isolate, no UI context available.
// Never show overlay from here; notification-only safe path.
@pragma('vm:entry-point')
void workManagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    if (taskName == WorkManagerTasks.backgroundServiceRecovery) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(PrefKeys.usageTrackingEnabled) != true) {
        return Future.value(true);
      }

      // Re-start the background service if it was killed by the OS.
      try {
        await NotificationService.instance.initialize();
        await initializeBackgroundService();
        await startUsageBackgroundService();
      } catch (error) {
        // Android may disallow starting a foreground service from background.
        // Reopening the app retries; WorkManager must not crash its isolate.
        debugPrint('Background recovery deferred: $error');
        return false;
      }
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _bootstrap();
  } catch (error, stack) {
    debugPrint('Startup failed: $error\n$stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      '앱을 준비하지 못했어요. 저장 공간을 확인하고 다시 시도해주세요.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  FilledButton(onPressed: main, child: const Text('다시 시도')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _bootstrap() async {
  await NotificationService.instance.initialize();
  if (adsEnabled) {
    unawaited(
      MobileAds.instance.initialize().catchError((Object error) {
        debugPrint('Ads unavailable: $error');
        return InitializationStatus({});
      }),
    );
  }
  await initializeBackgroundService();

  // WorkManager — 15-min recovery heartbeat for Samsung/Xiaomi battery killers.
  await Workmanager().initialize(workManagerCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    WorkManagerTasks.backgroundServiceRecovery,
    WorkManagerTasks.backgroundServiceRecovery,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

  // Copy default pet image to documents dir (no-op after first run).
  final defaultPetPath = await AssetCopyService.instance
      .ensureDefaultPetCopied();

  // Seed the default pet row if the pets table is empty.
  final petRepo = PetRepository();
  final existing = await petRepo.getAll();
  if (existing.isEmpty) {
    await petRepo.insert(
      PetModel(
        name: '기본 펫',
        type: 'default',
        imagePath: defaultPetPath,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  final settingsRepo = SettingsRepository();
  final usageRepo = UsageRepository();

  final timerProvider = TimerProvider();
  await timerProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppProvider(settingsRepo)..initialize(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(settingsRepo)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => PetProvider(petRepo, settingsRepo)..load(),
        ),
        ChangeNotifierProvider(create: (_) => UsageProvider(usageRepo)..load()),
        ChangeNotifierProxyProvider<PetProvider, TimerProvider>(
          create: (_) => timerProvider,
          update: (_, petProvider, timerProvider) {
            timerProvider!.updateActivePetCallback(
              () => petProvider.activePet?.imagePath,
            );
            return timerProvider;
          },
        ),
      ],
      child: const YeogiBwayongApp(),
    ),
  );
}
