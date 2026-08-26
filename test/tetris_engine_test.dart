import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/games/tetris/tetris_engine.dart';

/// Tahtayı doğrudan doldurmak için yardımcı (motorun içini test etmek adına).
void fillRow(TetrisGame game, int row, {int? except}) {
  for (var col = 0; col < TetrisGame.cols; col++) {
    if (col == except) continue;
    game.board[row * TetrisGame.cols + col] = Tetromino.o;
  }
}

int filledCells(TetrisGame game) => game.board.where((c) => c != null).length;

void main() {
  group('Parça biçimleri', () {
    test('her parça 4 hücreden oluşur ve 4 dönüşü vardır', () {
      for (final type in Tetromino.values) {
        final game = TetrisGame(random: Random(1));
        // Parçayı doğrudan test etmek için dönüşleri sırayla dene.
        for (var i = 0; i < 4; i++) {
          game.rotate();
          expect(game.currentCells.length, 4, reason: type.name);
        }
      }
    });

    test('O parçası döndürülünce yer değiştirmez', () {
      final game = TetrisGame(random: Random(1));
      while (game.current != Tetromino.o) {
        game.hardDrop();
        if (game.over) fail('O parçası çıkmadan oyun bitti');
      }

      final before = game.currentCells.toString();
      game.rotate();
      expect(game.currentCells.toString(), before);
    });
  });

  group('Hareket', () {
    test('parça duvarların dışına çıkamaz', () {
      final game = TetrisGame(random: Random(3));

      while (game.moveLeft()) {}
      final leftmost = game.currentCells.map((c) => c.col).reduce(min);
      expect(leftmost, 0);

      while (game.moveRight()) {}
      final rightmost = game.currentCells.map((c) => c.col).reduce(max);
      expect(rightmost, TetrisGame.cols - 1);
    });

    test('sert düşüş parçayı tabana yerleştirir ve puan verir', () {
      final game = TetrisGame(random: Random(5));

      final dropped = game.hardDrop();

      expect(dropped, greaterThan(0));
      expect(game.score, dropped * TetrisGame.hardDropPoint);
      expect(filledCells(game), 4);
    });

    test('yumuşak düşüş hücre başına puan verir', () {
      final game = TetrisGame(random: Random(5));

      game.softDrop();

      expect(game.score, TetrisGame.softDropPoint);
    });

    test('yerçekimi adımı parçayı bir satır indirir', () {
      final game = TetrisGame(random: Random(5));
      final before = game.currentCells.map((c) => c.row).reduce(min);

      game.tick();

      expect(game.currentCells.map((c) => c.row).reduce(min), before + 1);
      expect(game.score, 0, reason: 'yerçekimi puan kazandırmaz');
    });

    test('hayalet parça inilecek yeri gösterir', () {
      final game = TetrisGame(random: Random(7));

      final ghostBottom = game.ghostCells.map((c) => c.row).reduce(max);
      game.hardDrop();
      final landedBottom = game.board
          .asMap()
          .entries
          .where((e) => e.value != null)
          .map((e) => e.key ~/ TetrisGame.cols)
          .reduce(max);

      expect(ghostBottom, landedBottom);
    });
  });

  group('Satır temizleme', () {
    test('dolan satır silinir ve puan kazandırır', () {
      // Yatay I parçası tam olarak 0–3. sütunları doldurur.
      final game = TetrisGame(sequence: const [Tetromino.i]);
      final bottom = TetrisGame.rows - 1;
      for (var col = 4; col < TetrisGame.cols; col++) {
        game.board[bottom * TetrisGame.cols + col] = Tetromino.o;
      }

      while (game.moveLeft()) {}
      game.hardDrop();

      expect(game.lines, 1);
      expect(game.score, greaterThanOrEqualTo(TetrisGame.lineScores[1]));
      expect(
        List.generate(TetrisGame.cols, (c) => game.cellAt(bottom, c)),
        everyElement(isNull),
        reason: 'satır temizlenmeli',
      );
    });

    test('temizlenen satırın üstündekiler aşağı iner', () {
      final game = TetrisGame(sequence: const [Tetromino.i]);
      final bottom = TetrisGame.rows - 1;
      for (var col = 4; col < TetrisGame.cols; col++) {
        game.board[bottom * TetrisGame.cols + col] = Tetromino.o;
      }
      game.board[(bottom - 1) * TetrisGame.cols + 5] = Tetromino.t;

      while (game.moveLeft()) {}
      game.hardDrop();

      expect(game.cellAt(bottom, 5), Tetromino.t);
      expect(game.cellAt(bottom - 1, 5), isNull);
    });

    test('çoklu temizlik daha çok puan verir', () {
      expect(TetrisGame.lineScores[2], greaterThan(TetrisGame.lineScores[1]));
      expect(TetrisGame.lineScores[4], greaterThan(TetrisGame.lineScores[3]));
    });

    test('parça sırası verilince aynı parçalar tekrarlanır', () {
      final game = TetrisGame(
        sequence: const [Tetromino.i, Tetromino.o, Tetromino.t],
      );

      expect(game.current, Tetromino.i);
      expect(game.next, Tetromino.o);
      game.hardDrop();
      expect(game.current, Tetromino.o);
      expect(game.next, Tetromino.t);
    });
  });

  group('Seviye ve bitiş', () {
    test('her 10 satırda seviye artar ve hız yükselir', () {
      final game = TetrisGame(random: Random(2));
      expect(game.level, 1);
      final slow = game.gravity;

      game.lines = 10;
      expect(game.level, 2);
      expect(game.gravity, lessThan(slow));

      game.lines = 95;
      expect(game.level, 10);
      expect(game.gravity.inMilliseconds, greaterThanOrEqualTo(140));
    });

    test('tahta dolunca oyun biter', () {
      final game = TetrisGame(random: Random(4));

      var guard = 0;
      while (!game.over && guard++ < 500) {
        game.hardDrop();
      }

      expect(game.over, isTrue, reason: 'yığın tepeye ulaşınca bitmeli');
    });

    test('oyun bitince hareketler işlemez', () {
      final game = TetrisGame(random: Random(4))..endGame();

      expect(game.moveLeft(), isFalse);
      expect(game.rotate(), isFalse);
      expect(game.hardDrop(), 0);
    });

    test('yıldız sayısı 1 ile 5 arasında kalır', () {
      final game = TetrisGame(random: Random(1));
      expect(game.starsEarned, 1);

      game.score = 5000;
      expect(game.starsEarned, 5);
    });
  });
}
