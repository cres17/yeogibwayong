import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../core/constants.dart';
import '../data/repositories/pet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 반드시 @pragma — overlay isolate 진입점
@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _OverlayApp());
}

class _OverlayApp extends StatefulWidget {
  const _OverlayApp();

  @override
  State<_OverlayApp> createState() => _OverlayAppState();
}

class _OverlayAppState extends State<_OverlayApp> {
  String? _imagePath;
  Timer? _autoCloseTimer;
  StreamSubscription<dynamic>? _subscription;
  bool _receivedData = false;

  @override
  void initState() {
    super.initState();
    _subscription = FlutterOverlayWindow.overlayListener.listen(_onData);
    _autoCloseTimer = Timer(const Duration(seconds: 30), _close);
    _loadFallback();
  }

  Future<void> _loadFallback() async {
    // Native service startup can race the first shareData call.
    try {
      final pet = await PetRepository().getActive();
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      if (!mounted || _receivedData) return;
      _onData({
        OverlayDataKeys.petImagePath: pet?.imagePath,
        OverlayDataKeys.displaySeconds:
            prefs.getInt(PrefKeys.overlayDurationSeconds) ?? 5,
      });
    } catch (_) {
      /* The 30-second watchdog still closes the overlay. */
    }
  }

  void _onData(dynamic data) {
    if (!mounted || data is! Map) return;
    _receivedData = true;
    final map = Map<String, dynamic>.from(data);
    final path = map[OverlayDataKeys.petImagePath] as String?;
    final seconds = ((map[OverlayDataKeys.displaySeconds] as int?) ?? 5).clamp(
      3,
      30,
    );

    setState(() => _imagePath = path);

    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(Duration(seconds: seconds), _close);
  }

  void _close() => FlutterOverlayWindow.closeOverlay();

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No Provider, no Navigator — completely standalone
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Semantics(
          button: true,
          label: '펫 알림 닫기',
          child: GestureDetector(
            onTap: _close,
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_imagePath != null && File(_imagePath!).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_imagePath!),
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      const Icon(
                        Icons.pets,
                        size: 80,
                        color: Colors.pinkAccent,
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      '여기봐용! 👀',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
