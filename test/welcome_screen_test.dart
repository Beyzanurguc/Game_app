import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/main.dart';
import 'package:game_app/settings/app_settings.dart';
import 'package:game_app/settings/settings_storage.dart';
import 'package:game_app/settings/welcome_screen.dart';

import 'helpers.dart';

/// Giriş sayfasını telefon boyutunda açar.
Future<AppSettings> pumpWelcome(
  WidgetTester tester, {
  AppSettings? settings,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final target = settings ?? AppSettings();
  await tester.pumpWidget(wrapApp(const WelcomeScreen(), settings: target));
  await tester.pumpAndSettle();
  return target;
}

Finder get _nameField => find.byKey(const ValueKey('welcome_name'));
Finder get _slider => find.byKey(const ValueKey('welcome_limit_slider'));
Finder get _startButton => find.byKey(const ValueKey('welcome_start'));

void main() {
  group('sanitizeChildName', () {
    test('harf dışındaki her şeyi atar', () {
      expect(sanitizeChildName('Ayşe123'), 'Ayşe');
      expect(sanitizeChildName('Ali!@#'), 'Ali');
      expect(sanitizeChildName('42'), '');
    });

    test('boşlukları sadeleştirir ve kırpar', () {
      expect(sanitizeChildName('  Ela   Nur '), 'Ela Nur');
    });

    test('50 karakter sınırını uygular', () {
      final uzun = 'a' * 80;
      expect(sanitizeChildName(uzun).length, maxChildNameLength);
    });
  });

  group('AppSettings', () {
    test('giriş tamamlanınca ad ve limit kaydedilir', () async {
      final storage = MemorySettingsStorage();
      final settings = AppSettings(storage: storage);

      expect(settings.onboarded, isFalse);

      settings.completeOnboarding(name: 'Zeynep7', dailyGameLimit: 8);
      await settings.pending;

      expect(settings.onboarded, isTrue);
      expect(settings.childName, 'Zeynep');
      expect(settings.dailyGameLimit, 8);
      expect(storage.current.onboarded, isTrue);
      expect(storage.current.childName, 'Zeynep');
      expect(storage.current.dailyGameLimit, 8);
    });

    test('ad boş bırakılabilir', () {
      final settings = AppSettings();
      settings.completeOnboarding(dailyGameLimit: 3);

      expect(settings.childName, isEmpty);
      expect(settings.hasName, isFalse);
      expect(settings.onboarded, isTrue);
    });

    test('limit izin verilen aralığa çekilir', () {
      final settings = AppSettings();

      settings.completeOnboarding(dailyGameLimit: 99);
      expect(settings.dailyGameLimit, maxDailyGameLimit);

      settings.completeOnboarding(dailyGameLimit: 0);
      expect(settings.dailyGameLimit, minDailyGameLimit);
    });

    test('oynanan turlar günlük haktan düşer', () {
      final settings = AppSettings(
        state: const StoredSettings(dailyGameLimit: 2, onboarded: true),
      );

      expect(settings.remainingPlays, 2);
      expect(settings.canPlay, isTrue);

      settings.recordPlay();
      expect(settings.remainingPlays, 1);

      settings.recordPlay();
      expect(settings.playsToday, 2);
      expect(settings.remainingPlays, 0);
      expect(settings.canPlay, isFalse);
    });

    test('gün değişince hak yenilenir', () {
      var now = DateTime(2026, 8, 25, 20);
      final settings = AppSettings(
        state: const StoredSettings(dailyGameLimit: 1, onboarded: true),
        clock: () => now,
      );

      settings.recordPlay();
      expect(settings.canPlay, isFalse);

      now = DateTime(2026, 8, 26, 9);
      expect(settings.playsToday, 0);
      expect(settings.canPlay, isTrue);
    });
  });

  group('Giriş sayfası', () {
    testWidgets('uygulama ilk açılışta giriş sayfasına gelir', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(GameApp(collection: testCollection()));
      await tester.pumpAndSettle();

      expect(find.text('Hoş geldin!'), findsOneWidget);
      expect(find.text('Ebeveyne sor'), findsOneWidget);
      expect(find.text('Merhaba, Beyza!'), findsNothing);
    });

    testWidgets('ad ve limit kaydedilince ana sayfaya geçilir', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(GameApp(collection: testCollection()));
      await tester.pumpAndSettle();

      await tester.enterText(_nameField, 'Ela');
      await tester.pumpAndSettle();
      await tester.tap(_startButton);
      await tester.pumpAndSettle();

      expect(find.text('Merhaba, Ela!'), findsOneWidget);
      expect(find.text('Hoş geldin!'), findsNothing);
    });

    testWidgets('ad kutusu yalnızca harf kabul eder', (tester) async {
      await pumpWelcome(tester);

      await tester.enterText(_nameField, 'Ay2şe!.- 34');
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(_nameField);
      expect(field.controller?.text, 'Ayşe ');
    });

    testWidgets('ad kutusu 50 karakterde durur', (tester) async {
      await pumpWelcome(tester);

      await tester.enterText(_nameField, 'a' * 70);
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(_nameField);
      expect(field.controller?.text.length, maxChildNameLength);
    });

    testWidgets('ad boş bırakılırsa adsız selamlanır', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(GameApp(collection: testCollection()));
      await tester.pumpAndSettle();

      await tester.tap(_startButton);
      await tester.pumpAndSettle();

      expect(find.text('Merhaba!'), findsOneWidget);
    });

    testWidgets('sürgü limiti değiştirir ve kaydeder', (tester) async {
      final storage = MemorySettingsStorage();
      final settings = await pumpWelcome(
        tester,
        settings: AppSettings(storage: storage),
      );

      expect(find.text('Günde $defaultDailyGameLimit oyun'), findsOneWidget);

      // Sağ uca sürüklemek barı en yüksek değere getirir.
      await tester.drag(_slider, const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Günde $maxDailyGameLimit oyun'), findsOneWidget);

      await tester.tap(_startButton);
      await tester.pumpAndSettle();
      await settings.pending;

      expect(settings.dailyGameLimit, maxDailyGameLimit);
      expect(storage.current.dailyGameLimit, maxDailyGameLimit);
    });

    testWidgets('sürgü sol uçta 1 oyunun altına inmez', (tester) async {
      await pumpWelcome(tester);

      await tester.drag(_slider, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Günde $minDailyGameLimit oyun'), findsOneWidget);
    });
  });
}
