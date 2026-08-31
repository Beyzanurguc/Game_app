import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/games/yapboz/yapboz_engine.dart';

/// Tüm parçaları doğru yuvasına koyar.
void solve(YapbozEngine engine) {
  for (var i = 0; i < engine.slotCount; i++) {
    engine.place(i, i);
  }
}

void main() {
  group('kurulum', () {
    test('zorluk parça sayısını belirler', () {
      expect(YapbozEngine(difficulty: YapbozDifficulty.kolay).slotCount, 9);
      expect(YapbozEngine(difficulty: YapbozDifficulty.orta).slotCount, 16);
      expect(YapbozEngine(difficulty: YapbozDifficulty.zor).slotCount, 25);
    });

    test('başlangıçta tüm parçalar tepside, tahta boş', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.orta,
        random: Random(1),
      );

      expect(engine.tray.length, 16);
      expect(engine.tray.toSet(), {for (var i = 0; i < 16; i++) i});
      expect(engine.slots.every((s) => s == null), isTrue);
      expect(engine.correctCount, 0);
      expect(engine.isSolved, isFalse);
      expect(engine.progress, 0);
    });

    test('tepsi sıralı diziliş olarak bırakılmaz', () {
      // Farklı tohumlarda da tepsi baştan çözülmüş gibi durmamalı.
      for (var seed = 0; seed < 20; seed++) {
        final engine = YapbozEngine(
          difficulty: YapbozDifficulty.orta,
          random: Random(seed),
        );
        final inPlace = [
          for (var i = 0; i < engine.tray.length; i++)
            if (engine.tray[i] == i) i,
        ];
        expect(inPlace.length, lessThanOrEqualTo(engine.slotCount ~/ 4));
      }
    });
  });

  group('yerleştirme', () {
    test('doğru yuvaya konan parça sayılır, hata yazılmaz', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );

      expect(engine.place(4, 4), isTrue);
      expect(engine.correctCount, 1);
      expect(engine.mistakes, 0);
      expect(engine.moves, 1);
      expect(engine.tray, isNot(contains(4)));
      expect(engine.slotOf(4), 4);
      expect(engine.isSlotCorrect(4), isTrue);
    });

    test('yanlış yuvaya konan parça hata sayılır ama yerleşir', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );

      expect(engine.place(4, 0), isFalse);
      expect(engine.mistakes, 1);
      expect(engine.correctCount, 0);
      expect(engine.slotOf(4), 0);
      expect(engine.isSlotCorrect(0), isFalse);
    });

    test('dolu yuvaya tepsiden konunca eski parça tepsiye döner', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );

      engine.place(4, 0);
      engine.place(7, 0);

      expect(engine.slotOf(7), 0);
      expect(engine.slotOf(4), isNull);
      expect(engine.tray, contains(4));
    });

    test('iki yuva arasındaki taşıma takas yapar', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );

      engine.place(0, 1);
      engine.place(1, 0);
      // 0 -> yuva 0'a taşınırsa 1 ile yer değişmeli.
      engine.place(0, 0);

      expect(engine.slotOf(0), 0);
      expect(engine.slotOf(1), 1);
      expect(engine.correctCount, 2);
      // Takas tepsiye dokunmaz: geri kalan 7 parça yerinde durur.
      expect(engine.tray, hasLength(7));
    });

    test('aynı yuvaya tekrar bırakmak hamle saymaz', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );

      engine.place(3, 3);
      final moves = engine.moves;
      expect(engine.place(3, 3), isTrue);
      expect(engine.moves, moves, reason: 'yerinde duran parça hamle saymaz');
    });

    test('parça tepsiye geri gönderilebilir', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );

      engine.place(2, 2);
      engine.returnToTray(2);

      expect(engine.slots[2], isNull);
      expect(engine.tray, contains(2));
      expect(engine.correctCount, 0);
    });

    test('boş yuvayı tepsiye göndermek hiçbir şey yapmaz', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );

      final trayBefore = engine.tray.length;
      engine.returnToTray(5);

      expect(engine.tray.length, trayBefore);
      expect(engine.moves, 0);
    });
  });

  group('ipucu', () {
    test('bir parçayı doğru yuvasına taşır ve hata saymaz', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );

      final moved = engine.revealOne();

      expect(moved, isNotNull);
      expect(engine.isSlotCorrect(moved!), isTrue);
      expect(engine.mistakes, 0);
      expect(engine.correctCount, 1);
    });

    test('çözülmüş yapbozda null döner', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );
      solve(engine);

      expect(engine.revealOne(), isNull);
    });

    test('yanlış duran parçayı da düzeltir', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );
      // Hepsini yanlış yerleştir: her parça bir sonraki yuvaya.
      for (var i = 0; i < engine.slotCount; i++) {
        engine.place(i, (i + 1) % engine.slotCount);
      }
      expect(engine.correctCount, 0);

      final moved = engine.revealOne();
      expect(moved, isNotNull);
      expect(engine.isSlotCorrect(moved!), isTrue);
    });
  });

  group('çözüm ve puan', () {
    test('tüm parçalar yerine oturunca çözülür', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );
      solve(engine);

      expect(engine.isSolved, isTrue);
      expect(engine.correctCount, 9);
      expect(engine.progress, 1);
      expect(engine.tray, isEmpty);
    });

    test('çözülmeden puan ve yıldız verilmez', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );
      engine.place(0, 0);

      expect(engine.pointsFor(const Duration(seconds: 10)), 0);
      expect(engine.stars, 0);
    });

    test('hatasız ve hızlı çözüm tam puan ve üç yıldız verir', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );
      solve(engine);

      expect(engine.mistakes, 0);
      expect(engine.stars, 3);
      expect(engine.pointsFor(Duration.zero), 90, reason: '9 parça × 10');
    });

    test('hata ve süre puandan düşer', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );
      engine.place(0, 1); // hata
      engine.place(1, 0); // hata
      solve(engine);

      expect(engine.mistakes, 2);
      // 90 - (2 hata × 5) - (60 sn / 10 × 2) = 90 - 10 - 12 = 68
      expect(engine.pointsFor(const Duration(seconds: 60)), 68);
    });

    test('puan taban puanın beşte birinin altına inmez', () {
      final engine = YapbozEngine(
        difficulty: YapbozDifficulty.kolay,
        random: Random(1),
      );
      solve(engine);

      expect(engine.pointsFor(const Duration(hours: 1)), 18, reason: '90 / 5');
    });

    test('yıldız eşiği parça sayısına göre ölçeklenir', () {
      // 9 parçalık yapbozda eşik 3 hata (9 ~/ 3).
      YapbozEngine withMistakes(YapbozDifficulty difficulty, int mistakes) {
        final engine = YapbozEngine(difficulty: difficulty, random: Random(1));
        for (var i = 0; i < mistakes; i++) {
          // Her hata için bir parçayı yanlış yuvaya koy.
          engine.place(i, (i + 1) % engine.slotCount);
        }
        solve(engine);
        return engine;
      }

      expect(withMistakes(YapbozDifficulty.kolay, 0).stars, 3);
      expect(withMistakes(YapbozDifficulty.kolay, 3).stars, 2);
      expect(withMistakes(YapbozDifficulty.kolay, 4).stars, 1);
      // 25 parçada 8 hata hâlâ iki yıldız (25 ~/ 3 = 8).
      expect(withMistakes(YapbozDifficulty.zor, 8).stars, 2);
      expect(withMistakes(YapbozDifficulty.zor, 9).stars, 1);
    });
  });
}
