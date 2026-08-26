import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/games/sudoku/sudoku_engine.dart';

bool _isValidSolution(List<int> grid) {
  for (var i = 0; i < 9; i++) {
    final row = <int>{};
    final col = <int>{};
    final box = <int>{};
    for (var j = 0; j < 9; j++) {
      row.add(grid[i * 9 + j]);
      col.add(grid[j * 9 + i]);
      final r = (i ~/ 3) * 3 + j ~/ 3;
      final c = (i % 3) * 3 + j % 3;
      box.add(grid[r * 9 + c]);
    }
    if (row.length != 9 || col.length != 9 || box.length != 9) return false;
    if (row.contains(0)) return false;
  }
  return true;
}

void main() {
  group('SudokuPuzzle', () {
    test('üretilen çözüm geçerli bir sudoku tablosudur', () {
      final puzzle = SudokuPuzzle.generate(
        SudokuDifficulty.orta,
        random: Random(7),
      );
      expect(_isValidSolution(puzzle.solution), isTrue);
    });

    test('başlangıç tahtası çözümle uyumludur ve ipucu sayısı doğrudur', () {
      for (final difficulty in SudokuDifficulty.values) {
        final puzzle = SudokuPuzzle.generate(difficulty, random: Random(3));
        final clues = puzzle.givens.where((v) => v != 0).length;

        expect(
          clues,
          greaterThanOrEqualTo(difficulty.clues),
          reason: '${difficulty.label} için ipucu sayısı',
        );
        for (var i = 0; i < SudokuPuzzle.cellCount; i++) {
          if (puzzle.givens[i] != 0) {
            expect(puzzle.givens[i], puzzle.solution[i]);
          }
        }
      }
    });

    test('zorluk arttıkça açık hücre azalır', () {
      final kolay = SudokuPuzzle.generate(
        SudokuDifficulty.kolay,
        random: Random(11),
      ).givens.where((v) => v != 0).length;
      final zor = SudokuPuzzle.generate(
        SudokuDifficulty.zor,
        random: Random(11),
      ).givens.where((v) => v != 0).length;

      expect(zor, lessThan(kolay));
    });

    test('arePeers aynı satır, sütun ve kutuyu tanır', () {
      expect(SudokuPuzzle.arePeers(0, 8), isTrue); // aynı satır
      expect(SudokuPuzzle.arePeers(0, 72), isTrue); // aynı sütun
      expect(SudokuPuzzle.arePeers(0, 10), isTrue); // aynı kutu
      expect(SudokuPuzzle.arePeers(0, 80), isFalse);
      expect(SudokuPuzzle.arePeers(4, 4), isFalse); // kendisi
    });
  });

  group('SudokuScore', () {
    test('her doğru sayı puan kazandırır, seri bonusu büyür', () {
      final score = SudokuScore();

      expect(score.registerCorrect(), 10); // seri 1: bonus yok
      expect(score.registerCorrect(), 12); // seri 2
      expect(score.registerCorrect(), 14); // seri 3
      expect(score.points, 36);
      expect(score.bestStreak, 3);
    });

    test('seri bonusu üst sınırda durur', () {
      final score = SudokuScore();
      for (var i = 0; i < 10; i++) {
        score.registerCorrect();
      }
      expect(
        score.registerCorrect(),
        SudokuScore.correctBase + SudokuScore.maxStreakBonus,
      );
    });

    test('hata puan düşürmez ama seriyi sıfırlar', () {
      final score = SudokuScore()
        ..registerCorrect()
        ..registerCorrect();
      final before = score.points;

      score.registerMistake();

      expect(score.points, before);
      expect(score.streak, 0);
      expect(score.mistakes, 1);
      expect(score.registerCorrect(), 10); // seri baştan başlar
    });

    test('ipucu puandan düşer ve sıfırın altına inmez', () {
      final score = SudokuScore()..registerHint();
      expect(score.points, 0);

      score.registerCorrect(); // +10
      score.registerHint(); // -5
      expect(score.points, 5);
      expect(score.hints, 2);
    });

    test('hatasız ve hızlı bitiriş tüm bonusları verir', () {
      final score = SudokuScore()..registerCorrect();
      final bonus = score.finish(
        difficulty: SudokuDifficulty.orta,
        time: const Duration(minutes: 3),
      );

      expect(
        bonus,
        SudokuDifficulty.orta.completionBonus +
            SudokuScore.flawlessBonus +
            SudokuScore.speedBonus,
      );
      expect(score.finished, isTrue);
      expect(
        score.finish(difficulty: SudokuDifficulty.orta, time: Duration.zero),
        0,
      );
    });

    test('yavaş ve hatalı bitirişte yalnızca temel bonus verilir', () {
      final score = SudokuScore()..registerMistake();
      final bonus = score.finish(
        difficulty: SudokuDifficulty.kolay,
        time: const Duration(minutes: 10),
      );

      expect(bonus, SudokuDifficulty.kolay.completionBonus);
    });

    test('üç hatada oyun kaybedilir', () {
      final score = SudokuScore();

      expect(score.failed, isFalse);
      expect(score.mistakesLeft, SudokuScore.maxMistakes);

      score.registerMistake();
      score.registerMistake();
      expect(score.failed, isFalse);
      expect(score.mistakesLeft, 1);

      score.registerMistake();
      expect(score.failed, isTrue);
      expect(score.mistakesLeft, 0);
    });

    test('yıldız sayısı 1 ile 5 arasında kalır', () {
      expect(SudokuScore().starsEarned, 1);

      final score = SudokuScore();
      for (var i = 0; i < 100; i++) {
        score.registerCorrect();
      }
      expect(score.starsEarned, 5);
    });
  });
}
