import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/time_formatter.dart';
import '../../providers/pet_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/usage_provider.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/playful_pet_stage.dart';
import '../app_selection/app_selection_screen.dart';
import '../timer/timer_screen.dart';
import '../settings/settings_screen.dart';
import '../../providers/timer_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetProvider>().activePet;
    final usage = context.watch<UsageProvider>();
    final settings = context.watch<SettingsProvider>();
    final monitored = usage.monitoredApps;
    final totalLimit = monitored.fold<int>(
      0,
      (sum, app) => sum + app.dailyLimitSeconds,
    );
    final totalUsed = monitored.fold<int>(
      0,
      (sum, app) => sum + usage.todaySecondsFor(app.packageName),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('여기봐용'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              onPressed: settings.trackingBusy
                  ? null
                  : () => settings.setUsageTrackingEnabled(
                      !settings.usageTrackingEnabled,
                    ),
              icon: Icon(
                settings.usageTrackingEnabled
                    ? Icons.visibility
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              label: Text(settings.usageTrackingEnabled ? '감시 중' : '쉬는 중'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: usage.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  if (settings.trackingError != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(settings.trackingError!),
                        trailing: const Icon(Icons.settings_outlined),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ),
                  if (usage.error != null) Text(usage.error!),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('집중 타이머'),
                      subtitle: Text(
                        context.watch<TimerProvider>().isIdle
                            ? '5분부터 시작해요. 앱을 닫아도 이어져요.'
                            : '진행 중인 타이머와 완료 기록을 확인해요.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TimerScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PlayfulPetStage(pet: pet),
                  const SizedBox(height: 14),
                  _TodayOverviewCard(
                    watchedCount: monitored.length,
                    totalUsedSeconds: totalUsed,
                    totalLimitSeconds: totalLimit,
                    trackingEnabled: settings.usageTrackingEnabled,
                  ),
                  const SizedBox(height: 14),
                  _WatchedAppsCard(usage: usage),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: BannerAdWidget(),
          ),
        ],
      ),
    );
  }
}

class _TodayOverviewCard extends StatelessWidget {
  const _TodayOverviewCard({
    required this.watchedCount,
    required this.totalUsedSeconds,
    required this.totalLimitSeconds,
    required this.trackingEnabled,
  });

  final int watchedCount;
  final int totalUsedSeconds;
  final int totalLimitSeconds;
  final bool trackingEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final progress = totalLimitSeconds > 0
        ? (totalUsedSeconds / totalLimitSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: cs.primary),
              const SizedBox(width: 8),
              Text('오늘의 약속', style: theme.textTheme.titleLarge),
              const Spacer(),
              _StatusPill(enabled: trackingEnabled),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Metric(label: '지켜보는 앱', value: '$watchedCount개'),
              ),
              Expanded(
                child: _Metric(
                  label: '오늘 사용',
                  value: TimeFormatter.formatHHMM(totalUsedSeconds),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: '전체 제한',
                  value: totalLimitSeconds == 0
                      ? '-'
                      : TimeFormatter.formatHHMM(totalLimitSeconds),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: cs.surfaceContainerHighest,
              color: progress >= 1 ? cs.error : cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: enabled ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        enabled ? '켜짐' : '꺼짐',
        style: TextStyle(
          color: enabled ? cs.onPrimaryContainer : cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _WatchedAppsCard extends StatelessWidget {
  const _WatchedAppsCard({required this.usage});

  final UsageProvider usage;

  @override
  Widget build(BuildContext context) {
    final apps = usage.monitoredApps;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('앱별 제한', style: theme.textTheme.titleLarge),
              const Spacer(),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppSelectionScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('추가'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (apps.isEmpty)
            const _EmptyWatchedApps()
          else
            ...apps.map((app) {
              final used = usage.todaySecondsFor(app.packageName);
              return _UsageRow(
                appName: app.appName ?? app.packageName,
                usedSeconds: used,
                limitSeconds: app.dailyLimitSeconds,
              );
            }),
        ],
      ),
    );
  }
}

class _EmptyWatchedApps extends StatelessWidget {
  const _EmptyWatchedApps();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(Icons.tune, size: 42, color: cs.primary),
          const SizedBox(height: 10),
          Text('아직 제한한 앱이 없어요', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '앱을 고르고 하루 제한 시간을 정하면\n펫이 딱 맞춰 등장해요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _UsageRow extends StatelessWidget {
  const _UsageRow({
    required this.appName,
    required this.usedSeconds,
    required this.limitSeconds,
  });

  final String appName;
  final int usedSeconds;
  final int limitSeconds;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = limitSeconds > 0
        ? (usedSeconds / limitSeconds).clamp(0.0, 1.0)
        : 0.0;
    final exceeded = usedSeconds >= limitSeconds && limitSeconds > 0;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${TimeFormatter.formatHHMM(usedSeconds)} / '
                '${TimeFormatter.formatLimitMinutes(limitSeconds)}',
                style: TextStyle(
                  color: exceeded ? cs.error : cs.onSurfaceVariant,
                  fontWeight: exceeded ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: cs.surfaceContainerHighest,
              color: exceeded ? cs.error : cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
