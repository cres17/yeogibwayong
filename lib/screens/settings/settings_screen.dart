import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:usage_stats/usage_stats.dart';

import '../../providers/settings_provider.dart';
import '../../core/constants.dart';
import '../../screens/permission_guide/permission_guide_screen.dart';
import '../../services/oem_settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _notificationGranted = false;
  bool _overlayGranted = false;
  bool _usageGranted = false;
  bool _batteryGranted = false;
  bool _showOemTile = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _recheckPermissions();
    _detectOem();
    _loadVersion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _recheckPermissions();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = '${info.version}+${info.buildNumber}');
  }

  Future<void> _detectOem() async {
    final canOpen = await OemSettingsService.instance
        .canOpenAutostartSettings();
    if (!mounted) return;
    setState(() => _showOemTile = canOpen);
  }

  Future<void> _recheckPermissions() async {
    final notification = await Permission.notification.isGranted;
    final overlay = await FlutterOverlayWindow.isPermissionGranted();
    final usage = await _isUsageGranted();
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;

    if (!mounted) return;
    setState(() {
      _notificationGranted = notification;
      _overlayGranted = overlay;
      _usageGranted = usage;
      _batteryGranted = battery;
    });
  }

  Future<bool> _isUsageGranted() async {
    try {
      return await UsageStats.checkUsagePermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _requestNotification() async {
    await Permission.notification.request();
    await _recheckPermissions();
  }

  Future<void> _requestOverlay() async {
    await FlutterOverlayWindow.requestPermission();
  }

  Future<void> _requestUsage() async {
    await UsageStats.grantUsagePermission();
  }

  Future<void> _requestBattery() async {
    await Permission.ignoreBatteryOptimizations.request();
    await _recheckPermissions();
  }

  void _openPermissionGuide(PermissionType type) {
    Future<bool> check() => switch (type) {
      PermissionType.notification => Permission.notification.isGranted,
      PermissionType.overlay => FlutterOverlayWindow.isPermissionGranted(),
      PermissionType.usage => _isUsageGranted(),
      PermissionType.battery => Permission.ignoreBatteryOptimizations.isGranted,
    };
    final onRequest = switch (type) {
      PermissionType.notification => _requestNotification,
      PermissionType.overlay => _requestOverlay,
      PermissionType.usage => _requestUsage,
      PermissionType.battery => _requestBattery,
    };
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PermissionGuideScreen(
          type: type,
          checkPermission: check,
          onRequest: onRequest,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SettingsCard(
            title: '감시 상태',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('앱 사용 시간 감시'),
                subtitle: Text(
                  settings.trackingError ?? '켜져 있을 때만 백그라운드에서 사용 시간을 확인해요.',
                ),
                value: settings.usageTrackingEnabled,
                onChanged: settings.trackingBusy
                    ? null
                    : settings.setUsageTrackingEnabled,
              ),
            ],
          ),
          _SettingsCard(
            title: '알림',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('알림 받기'),
                value: settings.notificationEnabled,
                onChanged: settings.setNotificationEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('소리'),
                value: settings.soundEnabled,
                onChanged: settings.setSoundEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('진동'),
                value: settings.vibrationEnabled,
                onChanged: settings.setVibrationEnabled,
              ),
            ],
          ),
          _SettingsCard(
            title: '펫 등장',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('화면에 머무는 시간'),
                subtitle: Text('${settings.overlayDurationSeconds}초'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showOverlayDurationPicker(context, settings),
              ),
            ],
          ),
          _SettingsCard(
            title: '권한',
            children: [
              _PermissionTile(
                label: '알림',
                isGranted: _notificationGranted,
                onTap: () => _openPermissionGuide(PermissionType.notification),
              ),
              _PermissionTile(
                label: '다른 앱 위에 표시',
                isGranted: _overlayGranted,
                onTap: () => _openPermissionGuide(PermissionType.overlay),
              ),
              _PermissionTile(
                label: '앱 사용 기록',
                isGranted: _usageGranted,
                onTap: () => _openPermissionGuide(PermissionType.usage),
              ),
              _PermissionTile(
                label: '배터리 최적화 제외',
                isGranted: _batteryGranted,
                onTap: () => _openPermissionGuide(PermissionType.battery),
              ),
              if (_showOemTile)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.autorenew_outlined),
                  title: const Text('제조사 자동 시작 설정'),
                  subtitle: const Text('삼성/샤오미 기기에서 백그라운드 유지를 도와요.'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () =>
                      OemSettingsService.instance.openAutostartSettings(),
                ),
            ],
          ),
          _SettingsCard(
            title: '앱 정보',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('버전'),
                trailing: Text(_appVersion),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('개인정보 처리방침'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openPrivacyPolicy(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.article_outlined),
                title: const Text('오픈소스 라이선스'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: '여기봐용',
                  applicationVersion: _appVersion,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy(BuildContext context) {
    const privacyText =
        '앱 사용 시간, 제한 설정, 타이머 기록과 선택한 펫 사진은 이 기기의 앱 저장소에 보관돼요. '
        '사용 기록과 사진을 전송하는 자체 서버는 없어요. 앱 데이터를 삭제하거나 앱을 제거하면 로컬 기록이 삭제돼요. '
        '광고는 기본적으로 꺼져 있어요. 권한은 Android 설정에서 언제든 해제할 수 있어요.';
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('개인정보 처리방침'),
        content: SingleChildScrollView(
          child: Text(
            adsEnabled
                ? '$privacyText\n이 빌드는 광고가 활성화되어 Google AdMob SDK가 광고 요청 정보를 처리해요.'
                : privacyText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showOverlayDurationPicker(
    BuildContext context,
    SettingsProvider settings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: StatefulBuilder(
          builder: (_, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('펫 등장 시간', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('${settings.overlayDurationSeconds}초 동안 보여요'),
              Slider(
                value: settings.overlayDurationSeconds.toDouble(),
                min: 3,
                max: 30,
                divisions: 27,
                label: '${settings.overlayDurationSeconds}초',
                onChanged: (v) {
                  settings.setOverlayDurationSeconds(v.round());
                  setSheetState(() {});
                },
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.label,
    required this.isGranted,
    required this.onTap,
  });

  final String label;
  final bool isGranted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.cancel,
            color: isGranted ? cs.tertiary : cs.error,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            isGranted ? '허용됨' : '필요',
            style: TextStyle(
              color: isGranted ? cs.tertiary : cs.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
