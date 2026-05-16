import 'package:flutter/material.dart';

enum PermissionType { notification, overlay, usage, battery }

class PermissionGuideScreen extends StatelessWidget {
  const PermissionGuideScreen({
    super.key,
    required this.type,
    required this.isGranted,
    required this.onRequest,
  });

  final PermissionType type;
  final bool isGranted;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = _info;

    return Scaffold(
      appBar: AppBar(title: Text(info.title)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Icon(info.icon, size: 84, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            '왜 필요한가요?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(info.description),
          const SizedBox(height: 24),
          Text(
            '허용 방법',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(info.howTo),
          const SizedBox(height: 32),
          if (isGranted)
            _GrantedChip(label: '허용됨')
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(
                  type == PermissionType.notification
                      ? Icons.check_circle_outline
                      : Icons.open_in_new,
                ),
                label: Text(
                  type == PermissionType.notification ? '권한 요청' : '설정 열기',
                ),
                onPressed: onRequest,
              ),
            ),
        ],
      ),
    );
  }

  _PermissionInfo get _info => switch (type) {
    PermissionType.notification => const _PermissionInfo(
      title: '알림',
      description: '앱이 백그라운드에 있을 때도 상태를 알려주기 위해 필요해요.',
      howTo: '권한 요청 창이 뜨면 허용을 눌러주세요.',
      icon: Icons.notifications_outlined,
    ),
    PermissionType.overlay => const _PermissionInfo(
      title: '다른 앱 위에 표시',
      description: '제한 시간이 지나면 펫이 현재 화면 위에 살짝 나타나기 위해 필요해요.',
      howTo: '시스템 설정에서 여기봐용을 찾아 “다른 앱 위에 표시”를 허용해주세요.',
      icon: Icons.picture_in_picture_outlined,
    ),
    PermissionType.usage => const _PermissionInfo(
      title: '앱 사용 기록',
      description: '각 앱을 오늘 얼마나 사용했는지 계산하기 위해 필요해요.',
      howTo: '사용 정보 접근 설정에서 여기봐용을 허용해주세요.',
      icon: Icons.bar_chart_outlined,
    ),
    PermissionType.battery => const _PermissionInfo(
      title: '배터리 최적화 제외',
      description: '일부 기기에서 백그라운드 감시가 꺼지지 않도록 도와줘요.',
      howTo: '배터리 설정에서 여기봐용을 제한 없음 또는 최적화 제외로 설정해주세요.',
      icon: Icons.battery_charging_full_outlined,
    ),
  };
}

class _PermissionInfo {
  const _PermissionInfo({
    required this.title,
    required this.description,
    required this.howTo,
    required this.icon,
  });

  final String title;
  final String description;
  final String howTo;
  final IconData icon;
}

class _GrantedChip extends StatelessWidget {
  const _GrantedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
