import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
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
      await initializeBackgroundService();
      await startUsageBackgroundService();
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.instance.initialize();
  await MobileAds.instance.initialize();
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
          create: (ctx) => TimerProvider(
            getActivePetImagePath: () =>
                ctx.read<PetProvider>().activePet?.imagePath,
          ),
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
