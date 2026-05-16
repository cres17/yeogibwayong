import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/time_formatter.dart';
import '../../data/models/monitored_app_model.dart';
import '../../providers/usage_provider.dart';
import '../../services/usage_tracking_service.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  List<Application> _installedApps = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    final apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: false,
      onlyAppsWithLaunchIntent: true,
    );

    final filtered =
        apps
            .where((a) => !UsageTrackingService.isSystemPackage(a.packageName))
            .toList()
          ..sort(
            (a, b) =>
                a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
          );

    if (!mounted) return;
    setState(() {
      _installedApps = filtered;
      _loading = false;
    });
  }

  List<Application> get _filteredApps {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _installedApps;
    return _installedApps
        .where(
          (a) =>
              a.appName.toLowerCase().contains(q) ||
              a.packageName.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final usageProvider = context.watch<UsageProvider>();
    final monitoredMap = {
      for (final a in usageProvider.monitoredApps) a.packageName: a,
    };
    final selectedCount = monitoredMap.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('앱별 제한'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(98),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                _SummaryStrip(selectedCount: selectedCount),
                const SizedBox(height: 10),
                SearchBar(
                  hintText: '앱 이름 검색',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filteredApps.isEmpty
          ? const _EmptySearchState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _filteredApps.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final app = _filteredApps[index];
                final monitored = monitoredMap[app.packageName];
                return _AppLimitCard(
                  app: app,
                  monitored: monitored,
                  usedSeconds: usageProvider.todaySecondsFor(app.packageName),
                  onTap: () =>
                      _openLimitSheet(context, app, monitored, usageProvider),
                  onRemove: monitored == null
                      ? null
                      : () => usageProvider.removeMonitoredApp(app.packageName),
                );
              },
            ),
    );
  }

  Future<void> _openLimitSheet(
    BuildContext context,
    Application app,
    MonitoredAppModel? existing,
    UsageProvider provider,
  ) async {
    final limit = await showModalBottomSheet<int?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _LimitSheet(
        appName: app.appName,
        currentSeconds: existing?.dailyLimitSeconds,
      ),
    );
    if (limit == null) return;
    if (limit == 0) {
      await provider.removeMonitoredApp(app.packageName);
      return;
    }

    await provider.addMonitoredApp(
      MonitoredAppModel(
        id: existing?.id,
        packageName: app.packageName,
        appName: app.appName,
        dailyLimitSeconds: limit,
        isEnabled: true,
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        selectedCount == 0
            ? '앱을 누르면 하루 제한 시간을 바로 정할 수 있어요.'
            : '$selectedCount개 앱을 지켜보는 중이에요.',
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AppLimitCard extends StatelessWidget {
  const _AppLimitCard({
    required this.app,
    required this.monitored,
    required this.usedSeconds,
    required this.onTap,
    required this.onRemove,
  });

  final Application app;
  final MonitoredAppModel? monitored;
  final int usedSeconds;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = monitored != null;
    final limit = monitored?.dailyLimitSeconds ?? 0;
    final progress = limit > 0 ? (usedSeconds / limit).clamp(0.0, 1.0) : 0.0;

    return Material(
      color: active ? cs.primaryContainer.withValues(alpha: 0.28) : cs.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _AppIcon(app: app),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            app.appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (active)
                          Text(
                            TimeFormatter.formatLimitMinutes(limit),
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      active
                          ? '오늘 ${TimeFormatter.formatHHMM(usedSeconds)} 사용'
                          : '눌러서 제한 시간 정하기',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    if (active) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: cs.surfaceContainerHighest,
                          color: progress >= 1 ? cs.error : cs.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (active)
                IconButton(
                  tooltip: '제한 해제',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                )
              else
                Icon(Icons.add_circle_outline, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.app});

  final Application app;

  @override
  Widget build(BuildContext context) {
    if (app is ApplicationWithIcon) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          (app as ApplicationWithIcon).icon,
          width: 48,
          height: 48,
          gaplessPlayback: true,
        ),
      );
    }
    return const SizedBox(
      width: 48,
      height: 48,
      child: Icon(Icons.android, size: 36),
    );
  }
}

class _LimitSheet extends StatefulWidget {
  const _LimitSheet({required this.appName, required this.currentSeconds});

  final String appName;
  final int? currentSeconds;

  @override
  State<_LimitSheet> createState() => _LimitSheetState();
}

class _LimitSheetState extends State<_LimitSheet> {
  late int _minutes;
  static const _presets = [15, 30, 45, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    _minutes = ((widget.currentSeconds ?? 3600) ~/ 60).clamp(5, 480);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.appName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              '이 앱을 하루에 얼마나 쓰면 펫이 찾아올까요?',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 22),
            Center(
              child: Text(
                TimeFormatter.formatLimitMinutes(_minutes * 60),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: cs.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  onPressed: () => setState(() {
                    _minutes = (_minutes - 5).clamp(5, 480);
                  }),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 22),
                IconButton.filled(
                  onPressed: () => setState(() {
                    _minutes = (_minutes + 5).clamp(5, 480);
                  }),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets
                  .map(
                    (m) => ChoiceChip(
                      label: Text(TimeFormatter.formatLimitMinutes(m * 60)),
                      selected: _minutes == m,
                      onSelected: (_) => setState(() => _minutes = m),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                if (widget.currentSeconds != null)
                  TextButton(
                    onPressed: () => Navigator.pop(context, 0),
                    child: const Text('해제'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _minutes * 60),
                  icon: const Icon(Icons.check),
                  label: const Text('저장'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('검색 결과가 없어요'),
        ],
      ),
    );
  }
}
