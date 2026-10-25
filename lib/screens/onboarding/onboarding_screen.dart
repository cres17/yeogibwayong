import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:usage_stats/usage_stats.dart';

import '../../providers/app_provider.dart';
import '../../widgets/playful_pet_stage.dart';

enum _PermissionStep { notification, overlay, usage, battery, done }

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with WidgetsBindingObserver {
  _PermissionStep _step = _PermissionStep.notification;
  bool _checking = true;
  final Set<_PermissionStep> _skipped = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _advanceToNextNeeded());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _advanceToNextNeeded();
  }

  Future<void> _advanceToNextNeeded() async {
    if (!mounted) return;
    setState(() => _checking = true);

    final notification = await Permission.notification.isGranted;
    final overlay = await FlutterOverlayWindow.isPermissionGranted();
    final usage = await _isUsageGranted();
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;

    if (!mounted) return;
    setState(() {
      _checking = false;
      if (!notification && !_skipped.contains(_PermissionStep.notification)) {
        _step = _PermissionStep.notification;
      } else if (!overlay && !_skipped.contains(_PermissionStep.overlay)) {
        _step = _PermissionStep.overlay;
      } else if (!usage && !_skipped.contains(_PermissionStep.usage)) {
        _step = _PermissionStep.usage;
      } else if (!battery && !_skipped.contains(_PermissionStep.battery)) {
        _step = _PermissionStep.battery;
      } else {
        _step = _PermissionStep.done;
      }
    });
  }

  Future<bool> _isUsageGranted() async {
    try {
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _allowCurrentStep() async {
    switch (_step) {
      case _PermissionStep.notification:
        await Permission.notification.request();
      case _PermissionStep.overlay:
        await FlutterOverlayWindow.requestPermission();
      case _PermissionStep.usage:
        await UsageStats.grantUsagePermission();
      case _PermissionStep.battery:
        await Permission.ignoreBatteryOptimizations.request();
      case _PermissionStep.done:
        await _finish();
    }
    await _advanceToNextNeeded();
  }

  void _denyCurrentStep() {
    _skipped.add(_step);
    setState(() {
      _step = switch (_step) {
        _PermissionStep.notification => _PermissionStep.overlay,
        _PermissionStep.overlay => _PermissionStep.usage,
        _PermissionStep.usage => _PermissionStep.battery,
        _PermissionStep.battery => _PermissionStep.done,
        _PermissionStep.done => _PermissionStep.done,
      };
    });
  }

  Future<void> _finish() async {
    await context.read<AppProvider>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final info = _step.info;
    final done = _step == _PermissionStep.done;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '여기봐용',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '앱 사용 시간이 길어지면 펫이 살짝 찾아와서 다시 집중할 수 있게 도와줘요.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 16),
                ),
                const SizedBox(height: 24),
                const PlayfulPetStage(pet: null, compact: true),
                const SizedBox(height: 18),
                Center(
                  child: _checking
                      ? const CircularProgressIndicator()
                      : _PermissionPrompt(
                          icon: done ? Icons.check_circle : info.icon,
                          title: done ? '준비 끝!' : info.title,
                          description: done
                              ? '이제 앱별 제한 시간을 정하고 펫을 만나볼 수 있어요.'
                              : info.description,
                          stepLabel: done ? '완료' : info.stepLabel,
                        ),
                ),
                if (!done)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _checking ? null : _denyCurrentStep,
                          child: const Text('거절'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _checking ? null : _allowCurrentStep,
                          child: const Text('허락'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _finish,
                      child: const Text('시작하기'),
                    ),
                  ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text('나중에 설정할게요'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionPrompt extends StatelessWidget {
  const _PermissionPrompt({
    required this.icon,
    required this.title,
    required this.description,
    required this.stepLabel,
  });

  final IconData icon;
  final String title;
  final String description;
  final String stepLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              stepLabel,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Icon(icon, size: 68, color: cs.primary),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  const _StepInfo({
    required this.title,
    required this.description,
    required this.stepLabel,
    required this.icon,
  });

  final String title;
  final String description;
  final String stepLabel;
  final IconData icon;
}

extension on _PermissionStep {
  _StepInfo get info => switch (this) {
    _PermissionStep.notification => const _StepInfo(
      title: '알림을 보내도 될까요?',
      description: '백그라운드에서 앱 사용 상태와 펫 알림을 알려드릴게요.',
      stepLabel: '1 / 4',
      icon: Icons.notifications_outlined,
    ),
    _PermissionStep.overlay => const _StepInfo(
      title: '다른 앱 위에 펫을 띄워도 될까요?',
      description: '제한 시간이 지나면 현재 화면 위에 펫이 살짝 나타나요.',
      stepLabel: '2 / 4',
      icon: Icons.picture_in_picture_alt_outlined,
    ),
    _PermissionStep.usage => const _StepInfo(
      title: '앱 사용 기록을 확인해도 될까요?',
      description: '각 앱을 오늘 얼마나 썼는지 계산하기 위해 필요해요.',
      stepLabel: '3 / 4',
      icon: Icons.query_stats_outlined,
    ),
    _PermissionStep.battery => const _StepInfo(
      title: '배터리 최적화에서 제외할까요?',
      description: '일부 기기에서 백그라운드 감시가 꺼지지 않게 도와줘요.',
      stepLabel: '4 / 4',
      icon: Icons.battery_saver_outlined,
    ),
    _PermissionStep.done => const _StepInfo(
      title: '',
      description: '',
      stepLabel: '',
      icon: Icons.check_circle,
    ),
  };
}
