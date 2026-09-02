import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/firebase/session_scope.dart';
import 'package:game_app/settings/app_settings.dart';
import 'package:game_app/settings/settings_screen.dart';
import 'package:game_app/settings/settings_storage.dart';

import 'helpers.dart';

/// Ayarlar sayfasını telefon boyutunda açar.
///
/// [onSignOut] verilirse sayfa bir [SessionScope] içinde kurulur; çıkış
/// düğmesi ancak o zaman görünür.
Future<AppSettings> pumpSettings(
  WidgetTester tester, {
  AppSettings? settings,
  Future<void> Function()? onSignOut,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final target = settings ?? testSettings();
  const screen = SettingsScreen();
  await tester.pumpWidget(
    wrapApp(
      onSignOut == null
          ? screen
          : SessionScope(onSignOut: onSignOut, child: screen),
      settings: target,
    ),
  );
  await tester.pumpAndSettle();
  return target;
}

Finder get _nameField => find.byKey(const ValueKey('settings_name'));
Finder get _slider => find.byKey(const ValueKey('settings_limit_slider'));
Finder get _saveButton => find.byKey(const ValueKey('settings_save'));
Finder get _haptics => find.byKey(const ValueKey('settings_haptics'));
Finder get _signOutButton => find.byKey(const ValueKey('settings_sign_out'));
Finder get _signOutCancel =>
    find.byKey(const ValueKey('settings_sign_out_cancel'));
Finder get _signOutConfirm =>
    find.byKey(const ValueKey('settings_sign_out_confirm'));

void main() {
  group('AppSettings güncelleme', () {
    test('ad değiştirilir ve temizlenerek kaydedilir', () async {
      final storage = MemorySettingsStorage();
      final settings = testSettings(name: 'Ela', storage: storage);

      settings.updateChildName('  Zeynep7  Nur ');
      await settings.pending;

      expect(settings.childName, 'Zeynep Nur');
      expect(storage.current.childName, 'Zeynep Nur');
    });

    test('ad boşaltılabilir', () async {
      final settings = testSettings(name: 'Ela');

      settings.updateChildName('');

      expect(settings.childName, isEmpty);
      expect(settings.hasName, isFalse);
    });

    test('aynı değer yeniden yazılmaz', () async {
      final storage = MemorySettingsStorage();
      final settings = testSettings(
        name: 'Ela',
        dailyGameLimit: 5,
        storage: storage,
      );

      settings.updateChildName('Ela');
      settings.updateDailyGameLimit(5);
      await settings.pending;

      expect(storage.writes, 0);
    });

    test('limit izin verilen aralığa çekilir', () {
      final settings = testSettings(dailyGameLimit: 5);

      settings.updateDailyGameLimit(99);
      expect(settings.dailyGameLimit, maxDailyGameLimit);

      settings.updateDailyGameLimit(0);
      expect(settings.dailyGameLimit, minDailyGameLimit);
    });

    test('limit düşünce bugünkü sayaç korunur, hak azalır', () {
      final settings = testSettings(dailyGameLimit: 10, playsToday: 4);

      expect(settings.remainingPlays, 6);

      settings.updateDailyGameLimit(2);

      expect(settings.playsToday, 4);
      expect(settings.remainingPlays, 0);
      expect(settings.canPlay, isFalse);
    });

    test('limit yükselince kalan hak bugün de artar', () {
      final settings = testSettings(dailyGameLimit: 3, playsToday: 3);

      expect(settings.canPlay, isFalse);

      settings.updateDailyGameLimit(6);

      expect(settings.remainingPlays, 3);
      expect(settings.canPlay, isTrue);
    });

    test('onboarded durumu güncellemelerden etkilenmez', () {
      final settings = testSettings();

      settings.updateChildName('Ada');
      settings.updateDailyGameLimit(2);

      expect(settings.onboarded, isTrue);
    });
  });

  group('Ayarlar sayfası', () {
    testWidgets('kutular kayıtlı değerlerle açılır', (tester) async {
      await pumpSettings(
        tester,
        settings: testSettings(name: 'Ela', dailyGameLimit: 7),
      );

      final field = tester.widget<TextField>(_nameField);
      expect(field.controller?.text, 'Ela');
      expect(find.text('Günde 7 oyun'), findsOneWidget);
    });

    testWidgets('yeni ad kaydedilir', (tester) async {
      final storage = MemorySettingsStorage();
      final settings = await pumpSettings(
        tester,
        settings: testSettings(name: 'Ela', storage: storage),
      );

      await tester.enterText(_nameField, 'Zeynep');
      await tester.pumpAndSettle();
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();
      await settings.pending;

      expect(settings.childName, 'Zeynep');
      expect(storage.current.childName, 'Zeynep');
      expect(find.text('Ayarlar kaydedildi!'), findsOneWidget);
    });

    testWidgets('ad kutusu yalnızca harf kabul eder', (tester) async {
      await pumpSettings(tester);

      await tester.enterText(_nameField, 'Ay2şe!.- 34');
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(_nameField);
      expect(field.controller?.text, 'Ayşe ');
    });

    testWidgets('kaydedilen ad kutuda temiz görünür', (tester) async {
      await pumpSettings(tester);

      await tester.enterText(_nameField, 'Ayşe  ');
      await tester.pumpAndSettle();
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(_nameField);
      expect(field.controller?.text, 'Ayşe');
    });

    testWidgets('yeni limit sürgüden kaydedilir', (tester) async {
      final storage = MemorySettingsStorage();
      final settings = await pumpSettings(
        tester,
        settings: testSettings(dailyGameLimit: 5, storage: storage),
      );

      await tester.drag(_slider, const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Günde $maxDailyGameLimit oyun'), findsOneWidget);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();
      await settings.pending;

      expect(settings.dailyGameLimit, maxDailyGameLimit);
      expect(storage.current.dailyGameLimit, maxDailyGameLimit);
    });

    testWidgets('kaydedilmeden sürgü limiti değiştirmez', (tester) async {
      final settings = await pumpSettings(
        tester,
        settings: testSettings(dailyGameLimit: 5),
      );

      await tester.drag(_slider, const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(settings.dailyGameLimit, 5);
    });

    testWidgets('bugün oyun oynanmadıysa öyle yazar', (tester) async {
      await pumpSettings(tester, settings: testSettings(playsToday: 0));

      expect(find.text('Bugün henüz oyun oynanmadı.'), findsOneWidget);
    });

    testWidgets('sınır bugünkünün altına inince uyarır', (tester) async {
      await pumpSettings(
        tester,
        settings: testSettings(dailyGameLimit: 10, playsToday: 4),
      );

      expect(find.text('Bugün 4 oyun oynandı.'), findsOneWidget);

      await tester.drag(_slider, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('bu sınırla bugünlük hak biter'),
        findsOneWidget,
      );
    });
  });

  group('Titreşim anahtarı', () {
    testWidgets('kayıtlı değerle açılır', (tester) async {
      await pumpSettings(tester, settings: testSettings(hapticsEnabled: false));

      expect(tester.widget<Switch>(_haptics).value, isFalse);
    });

    testWidgets('açılınca örnek titreşim gönderir', (tester) async {
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

      await pumpSettings(tester, settings: testSettings(hapticsEnabled: false));

      // Kapalıdan açığa: örnek titreşim gitmeli.
      await tester.tap(_haptics);
      await tester.pumpAndSettle();
      expect(calls, ['HapticFeedbackType.mediumImpact']);

      // Açıktan kapalıya: hiçbir şey gitmemeli.
      await tester.tap(_haptics);
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
    });

    testWidgets('kaydet beklenmeden anında uygulanır', (tester) async {
      final storage = MemorySettingsStorage();
      final settings = await pumpSettings(
        tester,
        settings: testSettings(hapticsEnabled: true, storage: storage),
      );

      await tester.tap(_haptics);
      await tester.pumpAndSettle();
      await settings.pending;

      expect(settings.hapticsEnabled, isFalse);
      expect(storage.current.hapticsEnabled, isFalse);
      expect(tester.widget<Switch>(_haptics).value, isFalse);
    });
  });

  group('Çıkış', () {
    testWidgets('oturum kapsamı yoksa düğme gösterilmez', (tester) async {
      await pumpSettings(tester);

      expect(_signOutButton, findsNothing);
    });

    testWidgets('onaylanmadan çıkış yapılmaz', (tester) async {
      var signOuts = 0;
      await pumpSettings(tester, onSignOut: () async => signOuts++);

      // Ad kutusunun kendi kaydırıcısı da var; sayfanın listesi ilk sırada.
      await tester.scrollUntilVisible(
        _signOutButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(_signOutButton);
      await tester.pumpAndSettle();

      expect(_signOutConfirm, findsOneWidget);

      await tester.tap(_signOutCancel);
      await tester.pumpAndSettle();

      expect(signOuts, 0);
      expect(_signOutConfirm, findsNothing);
    });

    testWidgets('onaylanınca oturum kapatılır', (tester) async {
      var signOuts = 0;
      await pumpSettings(tester, onSignOut: () async => signOuts++);

      // Ad kutusunun kendi kaydırıcısı da var; sayfanın listesi ilk sırada.
      await tester.scrollUntilVisible(
        _signOutButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(_signOutButton);
      await tester.pumpAndSettle();

      await tester.tap(_signOutConfirm);
      await tester.pumpAndSettle();

      expect(signOuts, 1);
    });
  });
}
