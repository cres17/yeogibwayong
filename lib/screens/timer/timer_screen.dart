import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/timer_provider.dart';

String _formatRemaining(int totalSeconds) {
  final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Future<bool> _onPopInvoked(TimerProvider timer) async {
    if (!timer.isRunning && !timer.isPaused) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('타이머 취소'),
        content: const Text('진행 중인 타이머를 취소하고 나갈까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('계속'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('나가기'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await timer.cancel();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();

    return PopScope(
      canPop: provider.isIdle || provider.isCompleted,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final canLeave = await _onPopInvoked(provider);
        if (canLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('타이머')),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatRemaining(provider.remainingSeconds),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    '집중 시간은 기기에 저장돼요. 백그라운드 알림은 절전 설정에 따라 늦어질 수 있어요.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(provider.error!, textAlign: TextAlign.center),
                  ),
                if (provider.isCompleted)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('집중 완료! 잠깐 쉬어가요.'),
                  ),
                if (provider.busy)
                  const CircularProgressIndicator()
                else
                  _TimerControls(provider: provider),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  const _TimerControls({required this.provider});
  final TimerProvider provider;

  @override
  Widget build(BuildContext context) {
    return switch (provider.state) {
      TimerState.idle => _StartButton(onStart: () => _showPicker(context)),
      TimerState.running => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(onPressed: provider.pause, child: const Text('일시 정지')),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _confirmCancel(context),
            child: const Text('취소'),
          ),
        ],
      ),
      TimerState.paused => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton(onPressed: provider.resume, child: const Text('재개')),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _confirmCancel(context),
            child: const Text('취소'),
          ),
        ],
      ),
      TimerState.completed => FilledButton(
        onPressed: () {
          provider.acknowledgeCompletion();
        },
        child: const Text('확인'),
      ),
    };
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _DurationPicker(
        onSelected: (seconds) {
          Navigator.pop(context);
          context.read<TimerProvider>().start(seconds);
        },
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('타이머 취소'),
        content: const Text('진행 중인 타이머를 취소할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('아니오'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('취소'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<TimerProvider>().cancel();
    }
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onStart,
      icon: const Icon(Icons.play_arrow),
      label: const Text('타이머 시작'),
    );
  }
}

class _DurationPicker extends StatefulWidget {
  const _DurationPicker({required this.onSelected});
  final void Function(int seconds) onSelected;

  @override
  State<_DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<_DurationPicker> {
  int _minutes = 25;

  static const _presets = [5, 10, 15, 25, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('시간 선택', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _presets
                    .map(
                      (m) => ChoiceChip(
                        label: Text('$m분'),
                        selected: _minutes == m,
                        onSelected: (_) => setState(() => _minutes = m),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onSelected(_minutes * 60),
                  child: Text('$_minutes분 시작'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
