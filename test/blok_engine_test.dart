import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/games/blok/blok_engine.dart';

/// Tek hücrelik parça — testlerde tahtayı hücre hücre doldurmak için.
BlokPiece dot([BlokKind kind = BlokKind.fox]) =>
    BlokPiece.fromPattern(['X'], kind: kind);

/// Yatay çubuk.
BlokPiece bar(int length) => BlokPiece.fromPattern(['X' * length]);

void main() {
  group('kurulum', () {
    test('yeni oyunda tahta boş ve tepside üç parça var', () {
      final game = BlokGame(random: Random(1));

      expect(game.board.every((cell) => cell == null), isTrue);
      expect(game.remainingPieces, BlokGame.trayCount);
      expect(game.score, 0);
      expect(game.lines, 0);
      expect(game.over, isFalse);
    });
  });

  group('yerleştirme', () {
    test('geçerli hamle parçayı tahtaya yazar ve puan verir', () {
      final game = BlokGame(sequence: [bar(3)]);

      final result = game.place(0, 2, 1);

      expect(result, isNotNull);
      expect(game.cellAt(2, 1), isNotNull);
      expect(game.cellAt(2, 2), isNotNull);
      expect(game.cellAt(2, 3), isNotNull);
      expect(game.cellAt(2, 4), isNull);
      expect(game.score, 3 * BlokGame.pointPerCell);
      expect(game.remainingPieces, BlokGame.trayCount - 1);
    });

    test('tahta dışına taşan hamle reddedilir', () {
      final game = BlokGame(sequence: [bar(3)]);

      expect(game.place(0, 0, 6), isNull);
      expect(game.place(0, -1, 0), isNull);
      expect(game.score, 0);
      expect(game.remainingPieces, BlokGame.trayCount);
    });

    test('dolu hücrenin üstüne konamaz', () {
      final game = BlokGame(sequence: [dot()]);
      game.debugSetCell(4, 4, BlokKind.leaf);

      expect(game.canPlaceAt(0, 4, 4), isFalse);
      expect(game.place(0, 4, 4), isNull);
    });

    test('tepsi boşalınca üç yeni parça gelir', () {
      final game = BlokGame(sequence: [dot()]);

      game.place(0, 0, 0);
      game.place(1, 0, 1);
      expect(game.remainingPieces, 1);

      game.place(2, 0, 2);
      expect(game.remainingPieces, BlokGame.trayCount);
      expect(game.placed, 3);
    });
  });

  group('temizleme', () {
    test('dolan satır temizlenir ve puan kazandırır', () {
      final game = BlokGame(sequence: [dot()]);
      for (var col = 0; col < BlokGame.size - 1; col++) {
        game.debugSetCell(3, col, BlokKind.sky);
      }
      // Uzaktaki blok tahtanın tamamen boşalmasını (ve bonusu) engeller.
      game.debugSetCell(7, 0, BlokKind.sky);

      final result = game.place(0, 3, BlokGame.size - 1)!;

      expect(result.clearedLines, 1);
      expect(result.rows, [3]);
      expect(result.cols, isEmpty);
      expect(game.lines, 1);
      expect(
        List.generate(BlokGame.size, (col) => game.cellAt(3, col)),
        everyElement(isNull),
      );
      expect(game.score, BlokGame.pointPerCell + BlokGame.lineBase);
    });

    test('satır ve sütun aynı hamlede temizlenir', () {
      final game = BlokGame(sequence: [dot()]);
      for (var i = 0; i < BlokGame.size - 1; i++) {
        game.debugSetCell(0, i + 1, BlokKind.sun);
        game.debugSetCell(i + 1, 0, BlokKind.sun);
      }
      game.debugSetCell(5, 5, BlokKind.sun);

      final result = game.place(0, 0, 0)!;

      expect(result.clearedLines, 2);
      expect(result.rows, [0]);
      expect(result.cols, [0]);
      // Çoklu temizlik karesiyle büyür: 2 sıra -> 4 kat taban puan.
      expect(result.gained, BlokGame.pointPerCell + BlokGame.lineBase * 4);
    });

    test('üst üste temizlemeler kombo puanı ekler', () {
      final game = BlokGame(sequence: [dot()]);
      for (var col = 0; col < BlokGame.size - 1; col++) {
        game.debugSetCell(1, col, BlokKind.teal);
        game.debugSetCell(2, col, BlokKind.teal);
      }
      game.debugSetCell(7, 0, BlokKind.teal);

      final first = game.place(0, 1, BlokGame.size - 1)!;
      expect(first.combo, 1);

      final second = game.place(1, 2, BlokGame.size - 1)!;
      expect(second.combo, 2);
      expect(
        second.gained,
        BlokGame.pointPerCell + BlokGame.lineBase + BlokGame.comboBonus,
      );
      expect(game.bestCombo, 2);
    });

    test('temizlemeyen hamle komboyu sıfırlar', () {
      final game = BlokGame(sequence: [dot()]);
      for (var col = 0; col < BlokGame.size - 1; col++) {
        game.debugSetCell(5, col, BlokKind.berry);
      }

      game.place(0, 5, BlokGame.size - 1);
      expect(game.combo, 1);

      game.place(1, 7, 7);
      expect(game.combo, 0);
      expect(game.bestCombo, 1);
    });
  });

  group('oyun sonu', () {
    test('hiçbir parça sığmıyorsa oyun biter', () {
      final game = BlokGame(sequence: [dot(), bar(5), bar(5), bar(5)]);

      // Her satır ve sütunda iki boşluk bırakılır: dolu sıra oluşmaz ama
      // dağınık boşluklara 5'li çubuk da sığmaz.
      for (var row = 0; row < BlokGame.size; row++) {
        for (var col = 0; col < BlokGame.size; col++) {
          final hole = col == row || col == (row + 1) % BlokGame.size;
          game.debugSetCell(row, col, hole ? null : BlokKind.plum);
        }
      }
      game.debugSetTray([dot(), bar(5), bar(5)]);

      expect(game.hasAnyMove, isTrue);
      final result = game.place(0, 0, 0)!;

      // Satır da sütun da tamamlanmadı; kalan boşluğa 5'li çubuk sığmaz.
      expect(result.clearedLines, 0);
      expect(game.over, isTrue);
    });

    test('tahtayı boşaltmak ek puan kazandırır', () {
      final game = BlokGame(sequence: [dot()]);
      for (var col = 0; col < BlokGame.size - 1; col++) {
        game.debugSetCell(6, col, BlokKind.fox);
      }

      final result = game.place(0, 6, BlokGame.size - 1)!;

      expect(result.boardCleared, isTrue);
      expect(
        result.gained,
        BlokGame.pointPerCell + BlokGame.lineBase + BlokGame.clearBoardBonus,
      );
    });

    test('yıldız puanla birlikte artar ve 1–5 arasında kalır', () {
      final game = BlokGame(sequence: [dot()]);

      expect(game.starsEarned, 1);
      game.score = 1200;
      expect(game.starsEarned, 2);
      game.score = 99999;
      expect(game.starsEarned, 5);
    });
  });

  group('ipucu', () {
    test('satır temizleyen hamleyi tercih eder', () {
      final game = BlokGame(sequence: [dot()]);
      for (var col = 0; col < BlokGame.size - 1; col++) {
        game.debugSetCell(4, col, BlokKind.leaf);
      }

      final move = game.hint()!;

      expect(move.row, 4);
      expect(move.col, BlokGame.size - 1);
    });

    test('temizleyen hamle yoksa geçerli bir hamle döner', () {
      final game = BlokGame(sequence: [bar(2)]);

      final move = game.hint()!;

      expect(game.canPlaceAt(move.index, move.row, move.col), isTrue);
    });
  });
}
