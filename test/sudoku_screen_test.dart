import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/games/sudoku/sudoku_engine.dart';
import 'package:game_app/games/sudoku/sudoku_screen.dart';
import 'package:game_app/home_screen.dart';

import 'helpers.dart';

/// Ekranla aynı tohumu kullanarak beklenen bulmacayı yeniden üretir.
SudokuPuzzle expectedPuzzle(int seed) =>
    SudokuPuzzle.generate(SudokuDifficulty.kolay, random: Random(seed));

Future<SudokuPuzzle> pumpSudoku(WidgetTester tester, {int seed = 42}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrapApp(SudokuScreen(random: Random(seed))));
  return expectedPuzzle(seed);
}

/// Puan göstergesindeki değeri okur.
///
/// Puan bir AnimatedSwitcher içinde; geçiş bitmeden eski değer de ağaçta
/// durduğu için en son eklenen sayıyı okumak gerekir.
int readScore(WidgetTester tester) {
  final header = find
      .ancestor(of: find.text('PUAN'), matching: find.byType(Column))
      .first;
  final numbers = tester
      .widgetList<Text>(
        find.descendant(of: header, matching: find.byType(Text)),
      )
      .where((t) => int.tryParse(t.data ?? '') != null)
      .toList();
  return int.parse(numbers.last.data!);
}

/// Dokunup animasyonların oturmasını bekler (saniyelik sayaç settle'ı engeller).
Future<void> _tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> tapCell(WidgetTester tester, int index) =>
    _tapAndSettle(tester, find.byKey(ValueKey('cell_$index')));

Future<void> tapDigit(WidgetTester tester, int digit) =>
    _tapAndSettle(tester, find.byKey(ValueKey('key_$digit')));

void main() {
  testWidgets('oyun içinde alt gezinme çubuğu görünmez', (tester) async {
    await pumpSudoku(tester);

    expect(find.text('Sudoku'), findsOneWidget);
    for (final label in ['Oyunlar', 'Albüm', 'Rozetler', 'Ayarlar']) {
      expect(find.text(label), findsNothing);
    }
  });

  testWidgets('küçük ekranda araç çubuğu ve tuşlar taşmaz', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrapApp(SudokuScreen(random: Random(5))));
    await tester.pump();

    expect(tester.takeException(), isNull);
    for (final tool in ['Kalem', 'Silgi', 'İpucu 3', 'Yeni']) {
      expect(find.text(tool), findsOneWidget);
    }
  });

  testWidgets('doğru sayı puanı artırır, seri bonusu birikir', (tester) async {
    final puzzle = await pumpSudoku(tester);
    final empties = [
      for (var i = 0; i < SudokuPuzzle.cellCount; i++)
        if (puzzle.givens[i] == 0) i,
    ];

    expect(readScore(tester), 0);

    await tapCell(tester, empties[0]);
    await tapDigit(tester, puzzle.solution[empties[0]]);
    expect(readScore(tester), SudokuScore.correctBase);

    await tapCell(tester, empties[1]);
    await tapDigit(tester, puzzle.solution[empties[1]]);
    // İkinci doğru: 10 + seri bonusu 2
    expect(
      readScore(tester),
      SudokuScore.correctBase * 2 + SudokuScore.streakStep,
    );
  });

  /// Klavye kısayolu gönderir (hata ayıklama testleri için).
  Future<void> pressKey(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('F tuşu tahtayı doldurup ödül ekranını açar', (tester) async {
    await pumpSudoku(tester);

    await pressKey(tester, LogicalKeyboardKey.keyF);
    await tester.pumpAndSettle();

    expect(find.textContaining('Skorun:'), findsOneWidget);
    expect(find.text('KARTI KAYDET'), findsOneWidget);
  });

  testWidgets('X tuşu kasıtlı hata yapar', (tester) async {
    await pumpSudoku(tester);

    expect(find.text('Hata 0/3'), findsOneWidget);

    await pressKey(tester, LogicalKeyboardKey.keyX);

    expect(find.text('Hata 1/3'), findsOneWidget);
    expect(readScore(tester), 0);
  });

  testWidgets('üç hatada oyun biter ve kart kazanılmaz', (tester) async {
    await pumpSudoku(tester);

    for (var i = 0; i < SudokuScore.maxMistakes; i++) {
      await pressKey(tester, LogicalKeyboardKey.keyX);
    }
    await tester.pumpAndSettle();

    expect(find.text('Hata hakkın bitti'), findsOneWidget);
    expect(find.text('TEKRAR DENE'), findsOneWidget);
    expect(find.text('KARTI KAYDET'), findsNothing); // ödül kartı yok
  });

  testWidgets('oyun bitince "Tekrar Dene" yeni bulmaca başlatır', (
    tester,
  ) async {
    await pumpSudoku(tester);

    for (var i = 0; i < SudokuScore.maxMistakes; i++) {
      await pressKey(tester, LogicalKeyboardKey.keyX);
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('gameover_retry')));
    await tester.pumpAndSettle();

    expect(find.text('Hata hakkın bitti'), findsNothing);
    expect(find.text('Hata 0/3'), findsOneWidget);
    expect(find.text('İpucu 3'), findsOneWidget); // haklar da sıfırlandı
  });

  testWidgets('oyun bitince tahta kilitlenir', (tester) async {
    final puzzle = await pumpSudoku(tester);

    for (var i = 0; i < SudokuScore.maxMistakes; i++) {
      await pressKey(tester, LogicalKeyboardKey.keyX);
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('gameover_home')));
    await tester.pumpAndSettle();

    // Ana sayfaya dönerken ekran kapandığı için tahta erişilemez olur.
    expect(
      find.byKey(ValueKey('cell_${puzzle.givens.indexOf(0)}')),
      findsNothing,
    );
  });

  testWidgets('yanlış sayı puan kazandırmaz', (tester) async {
    final puzzle = await pumpSudoku(tester);
    final index = puzzle.givens.indexOf(0);
    final correct = puzzle.solution[index];
    final wrong = correct == 9 ? 1 : correct + 1;

    await tapCell(tester, index);
    await tapDigit(tester, wrong);

    expect(readScore(tester), 0);
    expect(find.text('Hata 1/3'), findsOneWidget);
  });

  testWidgets('aynı hücreyi silip yeniden yazmak puan tekrarlatmaz', (
    tester,
  ) async {
    final puzzle = await pumpSudoku(tester);
    final index = puzzle.givens.indexOf(0);

    await tapCell(tester, index);
    await tapDigit(tester, puzzle.solution[index]);
    expect(readScore(tester), SudokuScore.correctBase);

    await _tapAndSettle(tester, find.byKey(const ValueKey('tool_eraser')));
    await tapDigit(tester, puzzle.solution[index]);

    expect(readScore(tester), SudokuScore.correctBase);
  });

  testWidgets('ipucu puandan düşer', (tester) async {
    final puzzle = await pumpSudoku(tester);
    final index = puzzle.givens.indexOf(0);

    await tapCell(tester, index);
    await tapDigit(tester, puzzle.solution[index]); // +10
    await _tapAndSettle(tester, find.byKey(const ValueKey('tool_hint')));

    expect(readScore(tester), SudokuScore.correctBase - SudokuScore.hintCost);
    // Buton kalan hakkı gösterir: 3 - 1 = 2
    expect(find.text('İpucu 2'), findsOneWidget);
  });

  testWidgets('ipucu alınca tahta yerinden kaymaz', (tester) async {
    await pumpSudoku(tester);

    final before = tester.getTopLeft(find.byKey(const ValueKey('cell_0')));
    await _tapAndSettle(tester, find.byKey(const ValueKey('tool_hint')));
    final after = tester.getTopLeft(find.byKey(const ValueKey('cell_0')));

    expect(after, before);
  });

  testWidgets('ipucu hakkı 3 ile sınırlı, bitince uyarı verir', (tester) async {
    await pumpSudoku(tester);

    for (var i = 0; i < SudokuScore.maxHints; i++) {
      await _tapAndSettle(tester, find.byKey(const ValueKey('tool_hint')));
    }
    expect(find.text('İpucu 0'), findsOneWidget);

    await _tapAndSettle(tester, find.byKey(const ValueKey('tool_hint')));

    expect(
      find.textContaining('İpucu hakkın bitti!'),
      findsOneWidget,
      reason: 'dördüncü denemede uyarı çıkmalı',
    );
    expect(find.text('İpucu 0'), findsOneWidget);
  });

  testWidgets('kalem açıkken sayılar not olarak yazılır, puan değişmez', (
    tester,
  ) async {
    final puzzle = await pumpSudoku(tester);
    final index = puzzle.givens.indexOf(0);
    final value = puzzle.solution[index];

    await tapCell(tester, index);
    await _tapAndSettle(tester, find.byKey(const ValueKey('tool_pencil')));
    expect(
      find.text('Kalem açık: sayılar küçük not olarak yazılır.'),
      findsOneWidget,
    );

    await tapDigit(tester, value);
    expect(readScore(tester), 0);

    // Aynı tuşa tekrar basmak notu siler.
    await tapDigit(tester, value);
    expect(readScore(tester), 0);

    // Kalem kapanınca aynı sayı gerçek değer olarak yazılır.
    await _tapAndSettle(tester, find.byKey(const ValueKey('tool_pencil')));
    await tapDigit(tester, value);
    expect(readScore(tester), SudokuScore.correctBase);
  });

  testWidgets('yanlış değer silinip yenisi yazılabilir', (tester) async {
    final puzzle = await pumpSudoku(tester);
    final index = puzzle.givens.indexOf(0);
    final correct = puzzle.solution[index];
    final wrong = correct == 9 ? 1 : correct + 1;

    await tapCell(tester, index);
    await tapDigit(tester, wrong);
    expect(readScore(tester), 0);

    // Silgiyle temizle, sonra doğrusunu yaz.
    await _tapAndSettle(tester, find.byKey(const ValueKey('tool_eraser')));
    await tapDigit(tester, correct);
    expect(readScore(tester), SudokuScore.correctBase);
  });

  testWidgets('yanlış değerin üzerine doğrudan doğrusu yazılabilir', (
    tester,
  ) async {
    final puzzle = await pumpSudoku(tester);
    final index = puzzle.givens.indexOf(0);
    final correct = puzzle.solution[index];
    final wrong = correct == 9 ? 1 : correct + 1;

    await tapCell(tester, index);
    await tapDigit(tester, wrong);
    await tapDigit(tester, correct); // silmeden üzerine yaz

    expect(readScore(tester), SudokuScore.correctBase);
    expect(find.text('Hata 1/3'), findsOneWidget);
  });

  testWidgets('bulmaca bitince bilgi kartı ödül ekranı açılır', (tester) async {
    final puzzle = await pumpSudoku(tester);

    for (var i = 0; i < SudokuPuzzle.cellCount; i++) {
      if (puzzle.givens[i] != 0) continue;
      await tapCell(tester, i);
      await tapDigit(tester, puzzle.solution[i]);
    }
    await tester.pumpAndSettle();

    expect(find.textContaining('Skorun:'), findsOneWidget);
    expect(find.text('KARTI KAYDET'), findsOneWidget);
    expect(find.text('TEKRAR OYNA'), findsOneWidget);
    expect(find.text('Biliyor muydun?'), findsNothing); // önce gizli
  });

  testWidgets('ana sayfadan Sudoku açılır ve alt bar kaybolur', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrapApp(const HomeScreen()));

    expect(find.text('Rozetler'), findsOneWidget);

    await tester.tap(find.text('Sudoku'));
    await tester.pumpAndSettle();

    // Önce zorluk seçim sayfası açılır.
    expect(find.text('Zorluk seç'), findsOneWidget);
    expect(find.text('PUAN'), findsNothing);

    await tester.tap(find.text('Orta'));
    await tester.pumpAndSettle();

    expect(find.text('PUAN'), findsOneWidget);
    expect(find.text('Orta'), findsOneWidget); // zorluk rozeti
    expect(find.text('Rozetler'), findsNothing);
  });
}
