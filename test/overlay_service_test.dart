import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yeogibwayong/services/overlay_service.dart';
import 'package:yeogibwayong/core/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methods = MethodChannel('x-slayer/overlay_channel');
  const messages = BasicMessageChannel<dynamic>(
    'x-slayer/overlay_messenger',
    JSONMessageCodec(),
  );
  late bool active;
  late bool missingCloseReply;
  late int closeCalls;
  late Map<dynamic, dynamic>? shownArguments;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    active = false;
    missingCloseReply = false;
    closeCalls = 0;
    shownArguments = null;
    messenger.setMockMethodCallHandler(methods, (call) async {
      switch (call.method) {
        case 'checkPermission':
          return true;
        case 'isOverlayActive':
          return active;
        case 'showOverlay':
          shownArguments = call.arguments as Map;
          active = true;
          return null;
        case 'closeOverlay':
          closeCalls++;
          if (missingCloseReply) return Completer<bool?>().future;
          active = false;
          return true;
      }
      return null;
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(methods, null);
    messenger.setMockDecodedMessageHandler<dynamic>(messages, null);
  });
  testWidgets('missing overlay message acknowledgement cannot hang caller', (
    tester,
  ) async {
    messenger.setMockDecodedMessageHandler<dynamic>(
      messages,
      (_) => Completer<dynamic>().future,
    );
    var finished = false;
    final showing = OverlayService.instance
        .show(petImagePath: '/pet.png', triggerType: 'preview')
        .then((_) => finished = true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(finished, true);
    await showing;
  });
  testWidgets('overlay dimensions account for a dense phone display', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({PrefKeys.displayPixelRatio: 3.0});
    messenger.setMockDecodedMessageHandler<dynamic>(
      messages,
      (message) async => message,
    );
    await OverlayService.instance.show(
      petImagePath: '/pet.png',
      triggerType: 'preview',
    );
    expect(shownArguments?['width'], 720);
    expect(shownArguments?['height'], 720);
  });
  testWidgets('closing an inactive overlay is an immediate no-op', (
    tester,
  ) async {
    await OverlayService.instance.close();
    expect(closeCalls, 0);
  });
  testWidgets('a close race with a missing native reply is bounded', (
    tester,
  ) async {
    active = true;
    missingCloseReply = true;
    var finished = false;
    final closing = OverlayService.instance.close().then(
      (_) => finished = true,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(finished, true);
    expect(closeCalls, 1);
    await closing;
  });
}
