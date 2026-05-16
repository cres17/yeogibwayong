import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'providers/usage_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/shell/main_shell.dart';

class YeogiBwayongApp extends StatefulWidget {
  const YeogiBwayongApp({super.key});

  @override
  State<YeogiBwayongApp> createState() => _YeogiBwayongAppState();
}

class _YeogiBwayongAppState extends State<YeogiBwayongApp> {
  StreamSubscription<Map<String, dynamic>?>? _usageUpdateSub;

  @override
  void initState() {
    super.initState();
    _usageUpdateSub = FlutterBackgroundService()
        .on(ServiceEvents.usageUpdate)
        .listen((data) {
          if (data == null || !mounted) return;
          context.read<UsageProvider>().onUsageUpdate(data);
        });
  }

  @override
  void dispose() {
    _usageUpdateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '여기봐용',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    if (!appProvider.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!appProvider.onboardingDone) return const OnboardingScreen();

    return const MainShell();
  }
}
