import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../data/models/pet_model.dart';
import 'pet_avatar.dart';

enum PetMood { idle, charge, shake, combo, celebrate }

enum PlayGame { swipeCharge, shakeParty, tapCombo }

class PlayfulPetStage extends StatefulWidget {
  const PlayfulPetStage({super.key, required this.pet, this.compact = false});

  final PetModel? pet;
  final bool compact;

  @override
  State<PlayfulPetStage> createState() => _PlayfulPetStageState();
}

class _PlayfulPetStageState extends State<PlayfulPetStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  Timer? _idleTimer;
  Timer? _comboTimer;

  PlayGame _game = PlayGame.swipeCharge;
  PetMood _mood = PetMood.idle;
  double _charge = 0;
  double _shakeScore = 0;
  int _combo = 0;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..repeat(reverse: true);
    _accelerometerSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onAccelerometer, onError: (Object _) {});
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    _idleTimer?.cancel();
    _comboTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (_game != PlayGame.shakeParty || !mounted) return;
    final force = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final now = DateTime.now();
    if (force < 18 || now.difference(_lastShake).inMilliseconds < 170) return;
    _lastShake = now;
    setState(() {
      _mood = PetMood.shake;
      _shakeScore = (_shakeScore + 0.18).clamp(0.0, 1.0);
      if (_shakeScore >= 1) _mood = PetMood.celebrate;
    });
    _scheduleIdle();
  }

  void _scheduleIdle() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        if (_mood != PetMood.celebrate) _mood = PetMood.idle;
      });
    });
  }

  void _onVerticalDrag(DragUpdateDetails details) {
    if (_game != PlayGame.swipeCharge) return;
    final delta = -details.delta.dy / 180;
    setState(() {
      _mood = PetMood.charge;
      _charge = (_charge + delta).clamp(0.0, 1.0);
      if (_charge >= 1) _mood = PetMood.celebrate;
    });
  }

  void _onTap() {
    if (_game != PlayGame.tapCombo) {
      setState(() => _mood = PetMood.combo);
      _scheduleIdle();
      return;
    }
    _comboTimer?.cancel();
    setState(() {
      _mood = PetMood.combo;
      _combo += 1;
      if (_combo >= 12) _mood = PetMood.celebrate;
    });
    _comboTimer = Timer(const Duration(milliseconds: 850), () {
      if (!mounted || _mood == PetMood.celebrate) return;
      setState(() {
        _combo = 0;
        _mood = PetMood.idle;
      });
    });
  }

  void _resetGame() {
    setState(() {
      _charge = 0;
      _shakeScore = 0;
      _combo = 0;
      _mood = PetMood.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final stageHeight = widget.compact ? 240.0 : 360.0;
    final avatarSize = widget.compact ? 104.0 : 136.0;

    return GestureDetector(
      onTap: _onTap,
      onVerticalDragUpdate: _onVerticalDrag,
      onVerticalDragEnd: (_) => _scheduleIdle(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: stageHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _stageColor(cs),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SpeechBubble(text: _message, mood: _mood),
                ),
                if (!widget.compact)
                  IconButton(
                    tooltip: '다시 하기',
                    onPressed: _resetGame,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!widget.compact)
              _GameSelector(
                value: _game,
                onChanged: (game) {
                  setState(() => _game = game);
                  _resetGame();
                },
              ),
            const Spacer(),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value;
                final bob = math.sin(t * math.pi) * _bobAmount;
                final twist = math.sin(t * math.pi * 2) * _twistAmount;
                final scale = _scale + math.sin(t * math.pi) * _pulseAmount;

                return Transform.translate(
                  offset: Offset(0, -bob),
                  child: Transform.rotate(
                    angle: twist,
                    child: Transform.scale(scale: scale, child: child),
                  ),
                );
              },
              child: _PetActor(pet: widget.pet, size: avatarSize, mood: _mood),
            ),
            const Spacer(),
            _GameGauge(
              game: _game,
              charge: _charge,
              shakeScore: _shakeScore,
              combo: _combo,
            ),
            const SizedBox(height: 8),
            Text(
              _hint,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  double get _bobAmount => switch (_mood) {
    PetMood.idle => 6,
    PetMood.charge => 3,
    PetMood.shake => 14,
    PetMood.combo => 9,
    PetMood.celebrate => 18,
  };

  double get _twistAmount => switch (_mood) {
    PetMood.idle => 0.035,
    PetMood.charge => 0.02,
    PetMood.shake => 0.22,
    PetMood.combo => 0.11,
    PetMood.celebrate => 0.28,
  };

  double get _scale => switch (_mood) {
    PetMood.idle => 1.0,
    PetMood.charge => 1.08,
    PetMood.shake => 1.04,
    PetMood.combo => 1.12,
    PetMood.celebrate => 1.18,
  };

  double get _pulseAmount => _mood == PetMood.celebrate ? 0.08 : 0.025;

  Color _stageColor(ColorScheme cs) => switch (_mood) {
    PetMood.idle => cs.primaryContainer.withValues(alpha: 0.28),
    PetMood.charge => cs.tertiaryContainer.withValues(alpha: 0.55),
    PetMood.shake => cs.secondaryContainer.withValues(alpha: 0.58),
    PetMood.combo => cs.primaryContainer.withValues(alpha: 0.5),
    PetMood.celebrate => cs.tertiaryContainer.withValues(alpha: 0.78),
  };

  String get _message {
    if (_mood == PetMood.celebrate) return '성공! 펫 에너지 풀충전!';
    return switch (_game) {
      PlayGame.swipeCharge =>
        _mood == PetMood.charge ? '위로 쓱쓱! 더 올라가요!' : '위아래로 스와이프해서 간식 게이지를 채워요.',
      PlayGame.shakeParty =>
        _mood == PetMood.shake ? '흔들흔들! 파티 중!' : '핸드폰을 살짝 흔들어 깨워주세요.',
      PlayGame.tapCombo =>
        _mood == PetMood.combo ? '콤보 $_combo! 더 빠르게!' : '톡톡 연타해서 콤보를 만들어봐요.',
    };
  }

  String get _hint => switch (_game) {
    PlayGame.swipeCharge => '위로 스와이프할수록 게이지가 차요',
    PlayGame.shakeParty => '기기를 가볍게 흔들면 별이 터져요',
    PlayGame.tapCombo => '12콤보를 만들면 펫이 신나게 반응해요',
  };
}

class _GameSelector extends StatelessWidget {
  const _GameSelector({required this.value, required this.onChanged});

  final PlayGame value;
  final ValueChanged<PlayGame> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<PlayGame>(
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
      segments: const [
        ButtonSegment(
          value: PlayGame.swipeCharge,
          icon: Icon(Icons.swipe_vertical),
          label: Text('쓱쓱'),
        ),
        ButtonSegment(
          value: PlayGame.shakeParty,
          icon: Icon(Icons.vibration),
          label: Text('흔들'),
        ),
        ButtonSegment(
          value: PlayGame.tapCombo,
          icon: Icon(Icons.touch_app),
          label: Text('연타'),
        ),
      ],
    );
  }
}

class _GameGauge extends StatelessWidget {
  const _GameGauge({
    required this.game,
    required this.charge,
    required this.shakeScore,
    required this.combo,
  });

  final PlayGame game;
  final double charge;
  final double shakeScore;
  final int combo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final value = switch (game) {
      PlayGame.swipeCharge => charge,
      PlayGame.shakeParty => shakeScore,
      PlayGame.tapCombo => (combo / 12).clamp(0.0, 1.0),
    };
    final label = switch (game) {
      PlayGame.swipeCharge => '${(charge * 100).round()}%',
      PlayGame.shakeParty => '${(shakeScore * 100).round()}%',
      PlayGame.tapCombo => '$combo / 12',
    };

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: value,
              color: cs.primary,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _PetActor extends StatelessWidget {
  const _PetActor({required this.pet, required this.size, required this.mood});

  final PetModel? pet;
  final double size;
  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showBack = mood == PetMood.idle;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: showBack ? 1 : 0,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.9),
            ),
            child: Icon(Icons.pets, size: size * 0.48, color: cs.onPrimary),
          ),
        ),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: showBack ? 0 : 1,
          child: pet == null
              ? _FallbackPet(size: size)
              : PetAvatar(pet: pet!, size: size, showActiveBadge: false),
        ),
        if (mood == PetMood.celebrate)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _SparkPainter(color: cs.primary)),
            ),
          ),
        if (mood == PetMood.combo || mood == PetMood.charge)
          Positioned(
            top: 0,
            right: 0,
            child: Icon(Icons.favorite, color: cs.error, size: size * 0.22),
          ),
      ],
    );
  }
}

class _FallbackPet extends StatelessWidget {
  const _FallbackPet({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.surface,
        border: Border.all(color: cs.primary, width: 3),
      ),
      child: Icon(Icons.pets, size: size * 0.52, color: cs.primary),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text, required this.mood});

  final String text;
  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = mood != PetMood.idle;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: active ? cs.primary : cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? cs.onPrimary : cs.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.85);
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 10; i++) {
      final angle = i * math.pi / 5;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * 48;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * 72;
      canvas.drawLine(start, end, paint..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
