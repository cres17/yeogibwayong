import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/time_formatter.dart';
import '../../providers/usage_provider.dart';

enum _StatsView { daily, weekly }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  _StatsView _view = _StatsView.daily;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _dateString =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  void _load() => context.read<UsageProvider>().loadStats(_dateString);

  void _shiftDate(int days) {
    setState(() => _selectedDate = _selectedDate.add(Duration(days: days)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select<UsageProvider, bool>((p) => p.statsLoading);

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SegmentedButton<_StatsView>(
            segments: const [
              ButtonSegment(
                value: _StatsView.daily,
                label: Text('일간'),
                icon: Icon(Icons.today),
              ),
              ButtonSegment(
                value: _StatsView.weekly,
                label: Text('주간'),
                icon: Icon(Icons.date_range),
              ),
            ],
            selected: {_view},
            onSelectionChanged: (s) => setState(() => _view = s.first),
          ),
          const SizedBox(height: 10),
          _DateNavigator(
            date: _selectedDate,
            view: _view,
            onPrev: () => _shiftDate(_view == _StatsView.daily ? -1 : -7),
            onNext: _selectedDate.isBefore(_today())
                ? () => _shiftDate(_view == _StatsView.daily ? 1 : 7)
                : null,
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: _view == _StatsView.daily
                        ? const _DailyStats()
                        : _WeeklyStats(anchorDate: _selectedDate),
                  ),
          ),
        ],
      ),
    );
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }
}

class _DateNavigator extends StatelessWidget {
  const _DateNavigator({
    required this.date,
    required this.view,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime date;
  final _StatsView view;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final label = view == _StatsView.daily
        ? '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}'
        : _weekLabel(date);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        SizedBox(
          width: 170,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }

  static String _weekLabel(DateTime anchor) {
    final from = anchor.subtract(const Duration(days: 6));
    return '${from.month}/${from.day} - ${anchor.month}/${anchor.day}';
  }
}

class _DailyStats extends StatelessWidget {
  const _DailyStats();

  @override
  Widget build(BuildContext context) {
    final rows = context.select<UsageProvider, List<Map<String, dynamic>>>(
      (p) => p.dailyStats,
    );

    if (rows.isEmpty) {
      return const _EmptyPlaceholder(message: '이 날짜에는 사용 기록이 없어요.');
    }

    final display = rows.take(8).toList();
    final maxSeconds = display
        .map((row) => row['duration_seconds'] as int? ?? 0)
        .fold<int>(1, (max, value) => value > max ? value : max)
        .toDouble();

    return _ChartCard(
      title: '앱별 사용 시간 TOP ${display.length}',
      chart: _UsageBarChart(
        maxY: maxSeconds,
        values: [
          for (final row in display)
            (
              label: _shortPkgLabel(row['package_name'] as String? ?? ''),
              seconds: row['duration_seconds'] as int? ?? 0,
            ),
        ],
      ),
    );
  }
}

class _WeeklyStats extends StatelessWidget {
  const _WeeklyStats({required this.anchorDate});

  final DateTime anchorDate;

  @override
  Widget build(BuildContext context) {
    final rows = context.select<UsageProvider, List<Map<String, dynamic>>>(
      (p) => p.weeklyStats,
    );

    final values = List.generate(7, (i) {
      final d = anchorDate.subtract(Duration(days: 6 - i));
      final ds =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final match = rows.where((r) => r['date_string'] == ds).firstOrNull;
      return (
        label: _dayLabel(d),
        seconds: match?['total_seconds'] as int? ?? 0,
      );
    });

    final maxSeconds = values.fold<int>(
      0,
      (max, v) => v.seconds > max ? v.seconds : max,
    );
    if (maxSeconds == 0) {
      return const _EmptyPlaceholder(message: '이 기간에는 사용 기록이 없어요.');
    }

    return _ChartCard(
      title: '7일 사용 시간',
      chart: _UsageBarChart(maxY: maxSeconds.toDouble(), values: values),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.chart});

  final String title;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(child: chart),
        ],
      ),
    );
  }
}

class _UsageBarChart extends StatelessWidget {
  const _UsageBarChart({required this.maxY, required this.values});

  final double maxY;
  final List<({String label, int seconds})> values;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].seconds.toDouble(),
                  color: cs.primary,
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _niceInterval(maxY),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.outlineVariant, strokeWidth: 0.8),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: _niceInterval(maxY),
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  TimeFormatter.formatHHMM(value.toInt()),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= values.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    values[idx].label,
                    style: const TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => cs.surfaceContainerHighest,
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final item = values[group.x];
              return BarTooltipItem(
                '${item.label}\n${TimeFormatter.formatHHMM(item.seconds)}',
                TextStyle(color: cs.onSurface, fontSize: 11),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart, size: 64, color: cs.outline),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

double _niceInterval(double maxVal) {
  if (maxVal <= 300) return 60;
  if (maxVal <= 1800) return 300;
  if (maxVal <= 7200) return 1800;
  return 3600;
}

String _shortPkgLabel(String packageName) {
  final parts = packageName.split('.');
  final last = parts.isEmpty ? packageName : parts.last;
  return last.length > 10 ? last.substring(0, 10) : last;
}

String _dayLabel(DateTime d) {
  const days = ['월', '화', '수', '목', '금', '토', '일'];
  return days[d.weekday - 1];
}
