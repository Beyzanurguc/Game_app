import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/card_deck.dart';
import 'package:game_app/cards/reward_card_screen.dart';
import 'package:game_app/games/game_summary.dart';
import 'package:game_app/main.dart';
import 'package:game_app/settings/app_settings.dart';

import 'helpers.dart';

const _summary = GameSummary(
  kind: GameKind.tetris,
  points: 120,
  stars: 1,
  elapsed: Duration(minutes: 2),
  stats: [
    GameStat(icon: Icons.horizontal_rule_rounded, label: 'Satır', value: '3'),
  ],
);

Future<void> _pumpHome(WidgetTester tester, AppSettings settings) async {
  // Diğer ekran testleriyle aynı ölçü.
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    GameApp(collection: testCollection(), settings: settings),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Günlük oyun limiti', () {
    testWidgets('hak varken oyun açılır ve haktan bir tane düşer', (
      tester,
    ) async {
      final settings = testSettings(dailyGameLimit: 3);
      await _pumpHome(tester, settings);

      await tester.tap(find.text('Tetris'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('SIRADAKİ'), findsOneWidget); // oyun açıldı
      expect(settings.playsToday, 1);
      expect(settings.remainingPlays, 2);
    });

    testWidgets('hak bitince oyun açılmaz, uyarı gösterilir', (tester) async {
      final settings = testSettings(dailyGameLimit: 2, playsToday: 2);
      await _pumpHome(tester, settings);

      expect(settings.canPlay, isFalse);

      await tester.tap(find.text('Tetris'));
      await tester.pumpAndSettle();

      expect(find.text('Bugünlük bu kadar!'), findsOneWidget);
      expect(find.textContaining('2 oyun hakkını kullandın'), findsOneWidget);
      expect(find.text('SIRADAKİ'), findsNothing); // oyun açılmadı

      await tester.tap(find.byKey(const ValueKey('daily_limit_ok')));
      await tester.pumpAndSettle();

      expect(find.text('Bugünlük bu kadar!'), findsNothing);
      expect(find.text('Tetris'), findsOneWidget); // ana sayfadayız
      expect(settings.playsToday, 2); // reddedilen deneme hak yakmaz
    });

    testWidgets('sudoku zorluk seçilmeden vazgeçilince hak düşmez', (
      tester,
    ) async {
      final settings = testSettings(dailyGameLimit: 3);
      await _pumpHome(tester, settings);

      await tester.tap(find.text('Sudoku'));
      await tester.pumpAndSettle();
      expect(find.text('Zorluk seç'), findsOneWidget);

      // Seçim yapmadan sayfanın dışına dokunup kapat.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Zorluk seç'), findsNothing);
      expect(settings.playsToday, 0);
    });

    testWidgets('hak bitince ödül ekranında tekrar oyna görünmez', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrapApp(
          RewardCardScreen(card: cardDeck.last, summary: _summary),
          settings: testSettings(dailyGameLimit: 1, playsToday: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KARTI KAYDET'), findsOneWidget);
      expect(find.text('TEKRAR OYNA'), findsNothing);
    });

    testWidgets('hak varken ödül ekranında tekrar oyna görünür', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrapApp(
          RewardCardScreen(card: cardDeck.last, summary: _summary),
          settings: testSettings(dailyGameLimit: 5, playsToday: 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TEKRAR OYNA'), findsOneWidget);
    });
  });
}
