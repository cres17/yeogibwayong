class TimerSessionModel {
  final int? id;
  final int durationSeconds;
  final String? startedAt;
  final String? completedAt;
  final bool wasInterrupted;

  const TimerSessionModel({
    this.id,
    required this.durationSeconds,
    this.startedAt,
    this.completedAt,
    this.wasInterrupted = false,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'duration_seconds': durationSeconds,
        'started_at': startedAt,
        'completed_at': completedAt,
        'was_interrupted': wasInterrupted ? 1 : 0,
      };

  factory TimerSessionModel.fromMap(Map<String, dynamic> map) =>
      TimerSessionModel(
        id: map['id'] as int?,
        durationSeconds: map['duration_seconds'] as int,
        startedAt: map['started_at'] as String?,
        completedAt: map['completed_at'] as String?,
        wasInterrupted: (map['was_interrupted'] as int? ?? 0) == 1,
      );
}
