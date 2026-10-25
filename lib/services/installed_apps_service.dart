import 'package:flutter/services.dart';

class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.appName,
    this.icon,
  });
  final String packageName;
  final String appName;
  final Uint8List? icon;
}

class InstalledAppsService {
  static const _channel = MethodChannel('com.cres.yeogibwayong/apps');
  static Future<List<InstalledApp>> getInstalledApplications() async {
    final rows =
        await _channel.invokeListMethod<dynamic>('listLaunchableApps') ?? [];
    return rows
        .map(
          (row) => InstalledApp(
            packageName: row['packageName'] as String,
            appName: row['appName'] as String,
            icon: row['icon'] as Uint8List?,
          ),
        )
        .toList();
  }
}
