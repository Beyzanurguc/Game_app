import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/settings/app_settings.dart';
import 'package:game_app/settings/haptics.dart';
import 'package:game_app/settings/settings_storage.dart';

import 'helpers.dart';

/// Titreşim motoruna giden çağrıları yakalar (`vibration` paketinin kanalı).
List<Map<String, Object?>> _recordVibrations(WidgetTester tester) {
  final calls = <Map<String, Object?>>[];

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('vibration'),
    (call) async {
      if (call.method == 'vibrate') {
        calls.add(Map<String, Object?>.from(call.arguments as Map));
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('vibration'),
      null,
    ),
  );

  return calls;
}

/// Flutter'ın kendi titreşim çağrılarını yakalar.
List<String> _recordHaptics(WidgetTester tester) {
  final calls = <String>[];

  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add('${call.arguments}');
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );

  return calls;
}

/// Ayar kapsamının altında bir [BuildContext] kurar.
Future<BuildContext> _pumpScope(
  WidgetTester tester,
  AppSettings settings,
) async {
  await tester.pumpWidget(
    wrapApp(const SizedBox.shrink(key: ValueKey('scope')), settings: settings),
  );
  return tester.element(find.byKey(const ValueKey('scope')));
}

void main() {
  // Yetenek statik tutuluyor; testler birbirine sızmasın.
  tearDown(() => Haptics.debugSetSupport(useVibrator: false));

  group('AppSettings titreşim', () {
    test('varsayılan olarak açık', () {
      expect(AppSettings().hapticsEnabled, isTrue);
    });

    test('kapatılır ve diske yazılır', () async {
      final storage = MemorySettingsStorage();
      final settings = testSettings(storage: storage);

      settings.updateHaptics(false);
      await settings.pending;

      expect(settings.hapticsEnabled, isFalse);
      expect(storage.current.hapticsEnabled, isFalse);
    });

    test('aynı değer yeniden yazılmaz', () async {
      final storage = MemorySettingsStorage();
      final settings = testSettings(hapticsEnabled: true, storage: storage);

      settings.updateHaptics(true);
      await settings.pending;

      expect(storage.writes, 0);
    });

    test('ayar eklenmeden önceki kayıtlarda açık sayılır', () {
      // 'haptics' alanı olmayan eski bir kayıt.
      const raw = '{"name":"Ela","limit":5,"onboarded":true}';

      expect(StoredSettings.decode(raw).hapticsEnabled, isTrue);
      expect(StoredSettings.decode(raw).childName, 'Ela');
    });
  });

  group('buzz — titreşim motoru varken', () {
    testWidgets('süre ve güçle doğrudan motora gider', (tester) async {
      Haptics.debugSetSupport(useVibrator: true, hasAmplitude: true);
      final calls = _recordVibrations(tester);
      final context = await _pumpScope(
        tester,
        testSettings(hapticsEnabled: true),
      );

      buzz(context, Buzz.heavy);
      await tester.pump();

      expect(calls, hasLength(1));
      expect(calls.single['duration'], 50);
      expect(calls.single['amplitude'], 255);
    });

    testWidgets('güç ayarı yoksa amplitude gönderilmez', (tester) async {
      Haptics.debugSetSupport(useVibrator: true);
      final calls = _recordVibrations(tester);
      final context = await _pumpScope(
        tester,
        testSettings(hapticsEnabled: true),
      );

      buzz(context, Buzz.selection);
      await tester.pump();

      expect(calls.single['duration'], 12);
      expect(calls.single['amplitude'], -1, reason: 'cihazın varsayılanı');
    });

    testWidgets('türler birbirinden farklı şiddette', (tester) async {
      Haptics.debugSetSupport(useVibrator: true, hasAmplitude: true);
      final calls = _recordVibrations(tester);
      final context = await _pumpScope(
        tester,
        testSettings(hapticsEnabled: true),
      );

      for (final kind in Buzz.values) {
        buzz(context, kind);
      }
      await tester.pump();

      final durations = calls.map((c) => c['duration']! as int).toList();
      expect(durations, hasLength(Buzz.values.length));
      // selection en hafif, heavy en güçlü olmalı.
      expect(durations, orderedEquals(List.of(durations)..sort()));
    });

    testWidgets('ayar kapalıyken motora hiç gitmez', (tester) async {
      Haptics.debugSetSupport(useVibrator: true, hasAmplitude: true);
      final calls = _recordVibrations(tester);
      final context = await _pumpScope(
        tester,
        testSettings(hapticsEnabled: false),
      );

      buzz(context, Buzz.heavy);
      await tester.pump();

      expect(calls, isEmpty);
    });
  });

  group('buzz — motor yokken (iOS ve emülatör)', () {
    testWidgets('ayar açıkken titreşir', (tester) async {
      final calls = _recordHaptics(tester);
      final context = await _pumpScope(
        tester,
        testSettings(hapticsEnabled: true),
      );

      buzz(context, Buzz.medium);
      await tester.pump();

      expect(calls, ['HapticFeedbackType.mediumImpact']);
    });

    testWidgets('ayar kapalıyken hiç titreşmez', (tester) async {
      final calls = _recordHaptics(tester);
      final context = await _pumpScope(
        tester,
        testSettings(hapticsEnabled: false),
      );

      buzz(context, Buzz.medium);
      await tester.pump();

      expect(calls, isEmpty);
    });

    testWidgets('her tür kendi geri bildirimini gönderir', (tester) async {
      final calls = _recordHaptics(tester);
      final context = await _pumpScope(
        tester,
        testSettings(hapticsEnabled: true),
      );

      for (final (kind, expected) in const [
        (Buzz.selection, 'HapticFeedbackType.selectionClick'),
        (Buzz.light, 'HapticFeedbackType.lightImpact'),
        (Buzz.heavy, 'HapticFeedbackType.heavyImpact'),
      ]) {
        buzz(context, kind);
        await tester.pump();

        expect(calls.last, expected);
      }
    });
  });
}
