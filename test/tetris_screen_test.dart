import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/games/tetris/tetris_engine.dart';
import 'package:game_app/games/tetris/tetris_screen.dart';

import 'helpers.dart';

/// Ekranı sabit parça dizisiyle açar (deterministik test için).
Future<void> pumpTetris(
  WidgetTester tester, {
  List<Tetromino> sequence = const [Tetromino.i],
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrapApp(TetrisScreen(sequence: sequence)));
  await tester.pump();
}

/// Puan göstergesindeki değeri okur.
///
/// Puan bir AnimatedSwitcher içinde; geçiş sırasında eski değer de ağaçta
/// kaldığı için en son eklenen okunur.
int readScore(WidgetTester tester) {
  final scores = tester
      .widgetList<Text>(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('tetris_score_'),
        ),
      )
      .toList();
  return int.parse(scores.last.data!);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  testWidgets('oyun ekranı açılır ve kontroller görünür', (tester) async {
    await pumpTetris(tester);

    expect(find.text('SIRADAKİ'), findsOneWidget);
    expect(readScore(tester), 0);
    expect(find.text('Seviye 1'), findsOneWidget);
    expect(find.text('Satır 0'), findsOneWidget);
    expect(find.text('AŞAĞI'), findsOneWidget);

    // Oyun içinde alt gezinme çubuğu yok.
    for (final label in ['Oyunlar', 'Albüm', 'Rozetler', 'Ayarlar']) {
      expect(find.text(label), findsNothing);
    }
  });

  /// Hayalet (inecek yer) hücrelerini sayar.
  int ghostCellCount(WidgetTester tester) => tester
      .widgetList(
        find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('ghost_'),
        ),
      )
      .length;

  testWidgets('hayalet parça tahtada gösterilir', (tester) async {
    await pumpTetris(tester);

    expect(
      ghostCellCount(tester),
      4,
      reason: 'parçanın ineceği yer 4 hücreyle işaretlenmeli',
    );

    // Parça hareket edince hayalet de yer değiştirir ama görünmeye devam eder.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(ghostCellCount(tester), 4);
  });

  testWidgets('satır temizlenince kutlama yazısı çıkar', (tester) async {
    // 2x2'lik O parçaları: beş tanesi alt iki satırı tamamen doldurur.
    await pumpTetris(tester, sequence: const [Tetromino.o]);

    Future<void> press(LogicalKeyboardKey key, [int times = 1]) async {
      for (var i = 0; i < times; i++) {
        await tester.sendKeyEvent(key);
      }
      await tester.pump();
    }

    for (final offset in [0, 2, 4, 6, 8]) {
      await press(LogicalKeyboardKey.arrowLeft, 5); // en sola daya
      await press(LogicalKeyboardKey.arrowRight, offset);
      await press(LogicalKeyboardKey.space); // sert düşüş
    }
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('2 SATIR!'), findsOneWidget);
    expect(find.text('Satır 2'), findsOneWidget);

    // Kutlama kısa süre sonra kaybolur (AnimatedSwitcher çıkış animasyonu
    // için ek bir kare gerekir).
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2 SATIR!'), findsNothing);
  });

  testWidgets('aşağı düğmesi puan kazandırır', (tester) async {
    await pumpTetris(tester);
    expect(readScore(tester), 0);

    await tapKey(tester, 'tetris_drop_button');

    expect(readScore(tester), TetrisGame.softDropPoint);
  });

  testWidgets('aşağı düğmesini basılı tutmak sert düşüş yapar', (tester) async {
    await pumpTetris(tester);

    await tester.longPress(find.byKey(const ValueKey('tetris_drop')));
    await tester.pump();

    // Sert düşüş taban puanından çok daha fazlasını verir.
    expect(readScore(tester), greaterThan(TetrisGame.softDropPoint * 5));
  });

  testWidgets('klavye ok tuşları ve boşluk çalışır', (tester) async {
    await pumpTetris(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(readScore(tester), 0, reason: 'hareket puan kazandırmaz');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(readScore(tester), TetrisGame.softDropPoint);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(readScore(tester), greaterThan(TetrisGame.softDropPoint));
  });

  testWidgets('duraklat düğmesi mola ekranını açar', (tester) async {
    await pumpTetris(tester);

    await tapKey(tester, 'tetris_pause');
    await tester.pumpAndSettle();

    expect(find.text('Mola verdik'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pause_resume')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Mola verdik'), findsNothing);
    expect(find.text('AŞAĞI'), findsOneWidget);
  });

  testWidgets('X tuşu oyunu bitirip bilgi kartı ödülünü açar', (tester) async {
    await pumpTetris(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyX);
    await tester.pumpAndSettle();

    expect(find.textContaining('Skorun:'), findsOneWidget);
    expect(find.text('KARTI KAYDET'), findsOneWidget);

    // Tetris'e özel istatistikler listenin altında.
    await tester.scrollUntilVisible(
      find.text('Satır'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Satır'), findsOneWidget);
    expect(find.text('Seviye'), findsOneWidget);
  });

  testWidgets('ilerleme varken geri tuşu onay ister', (tester) async {
    await pumpTetris(tester);

    await tapKey(tester, 'tetris_drop_button'); // puan kazan
    await tapKey(tester, 'tetris_back');
    await tester.pumpAndSettle();

    expect(find.text('Şimdiden gidiyor musun?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('exit_stay')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('AŞAĞI'), findsOneWidget); // oyunda kalır
  });
}
