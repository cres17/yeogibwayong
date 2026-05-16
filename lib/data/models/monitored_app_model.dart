class MonitoredAppModel {
  final int? id;
  final String packageName;
  final String? appName;
  final int dailyLimitSeconds;
  final bool isEnabled;

  const MonitoredAppModel({
    this.id,
    required this.packageName,
    this.appName,
    required this.dailyLimitSeconds,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'package_name': packageName,
        'app_name': appName,
        'daily_limit_seconds': dailyLimitSeconds,
        'is_enabled': isEnabled ? 1 : 0,
      };

  factory MonitoredAppModel.fromMap(Map<String, dynamic> map) =>
      MonitoredAppModel(
        id: map['id'] as int?,
        packageName: map['package_name'] as String,
        appName: map['app_name'] as String?,
        dailyLimitSeconds: map['daily_limit_seconds'] as int,
        isEnabled: (map['is_enabled'] as int? ?? 1) == 1,
      );
}
