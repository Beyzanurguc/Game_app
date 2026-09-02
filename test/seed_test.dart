import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/info_card.dart';

/// Firestore'a yüklenecek tohum verinin doğruluğunu kontrol eder.
///
/// İçerik uygulamadan çıkıp Firestore'a taşındı; artık derleyici onu
/// denetlemiyor. `seed/` altındaki JSON dosyaları yüklemenin tek kaynağı
/// olduğu için doğrulama buraya taşındı.
Map<String, dynamic> _readJson(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path bulunamadı');
  return (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();
}

void main() {
  group('seed/cards.json', () {
    late Map<String, dynamic> cards;

    setUpAll(() => cards = _readJson('seed/cards.json'));

    test('100 kart var ve kimlikler tekil', () {
      expect(cards.length, 100);
      expect(cards.keys.toSet().length, 100);
    });

    test('her kartın zorunlu alanları dolu', () {
      for (final entry in cards.entries) {
        final card = (entry.value as Map).cast<String, dynamic>();
        for (final field in ['title', 'question', 'answer', 'emoji']) {
          expect(
            card[field],
            isA<String>().having((s) => s.trim(), field, isNotEmpty),
            reason: '${entry.key}.$field',
          );
        }
        expect(card['facts'], isA<List>(), reason: entry.key);
        expect((card['facts'] as List), isNotEmpty, reason: entry.key);
      }
    });

    test('kategoriler tanınan değerler', () {
      final names = CardCategory.values.map((c) => c.name).toSet();
      for (final entry in cards.entries) {
        final category = (entry.value as Map)['category'];
        expect(names, contains(category), reason: entry.key);
      }
    });

    test('sıra numaraları 0..99 arası ve tekil', () {
      final orders = [
        for (final value in cards.values) (value as Map)['order'] as int,
      ]..sort();
      expect(orders, List.generate(100, (i) => i));
    });

    test('her kartın kullanılabilir bir quiz sorusu var', () {
      for (final entry in cards.entries) {
        final quiz = QuizItem.fromMap((entry.value as Map)['quiz']);
        expect(quiz, isNotNull, reason: '${entry.key}: quiz yok');
        expect(quiz!.isUsable, isTrue, reason: '${entry.key}: quiz kullanılamaz');
      }
    });

    test('çevre kategorisi en kalabalık', () {
      final counts = <String, int>{};
      for (final value in cards.values) {
        final category = (value as Map)['category'] as String;
        counts[category] = (counts[category] ?? 0) + 1;
      }
      final cevre = counts['cevre'] ?? 0;
      for (final entry in counts.entries) {
        if (entry.key == 'cevre') continue;
        expect(entry.value, lessThan(cevre), reason: entry.key);
      }
    });

    test('InfoCard.fromMap tohumu eksiksiz okuyabiliyor', () {
      // Yükleme betiği ne yazıyorsa uygulama onu okuyabilmeli.
      for (final entry in cards.entries) {
        final card = InfoCard.fromMap(
          entry.key,
          (entry.value as Map).cast<String, dynamic>(),
        );
        expect(card.title, isNotEmpty, reason: entry.key);
        expect(card.facts, isNotEmpty, reason: entry.key);
        expect(card.quiz?.isUsable, isTrue, reason: entry.key);
      }
    });
  });

  group('seed/puzzles.json', () {
    late Map<String, dynamic> puzzles;

    setUpAll(() => puzzles = _readJson('seed/puzzles.json'));

    test('her yapbozun zorunlu alanları dolu', () {
      for (final entry in puzzles.entries) {
        final puzzle = (entry.value as Map).cast<String, dynamic>();
        expect(puzzle['title'], isA<String>(), reason: entry.key);
        expect(puzzle['sourceAsset'], 'seed/puzzles/${entry.key}.jpg');
        expect(puzzle['accent'], isA<int>(), reason: entry.key);
        expect(puzzle['icon'], isA<String>(), reason: entry.key);
        expect(puzzle['order'], isA<int>(), reason: entry.key);
      }
    });

    test('yüklenecek görsel dosyaları diskte var', () {
      for (final entry in puzzles.entries) {
        final source = (entry.value as Map)['sourceAsset'] as String;
        expect(
          File(source).existsSync(),
          isTrue,
          reason: '${entry.key}: $source bulunamadı',
        );
      }
    });

    testWidgets('her görsel kare ve 1200 piksel', (tester) async {
      // Yapboz ızgarası kare; kare olmayan görsel tahtada sessizce kırpılır.
      final sizes = await tester.runAsync(() async {
        final result = <String, (int, int)>{};
        for (final entry in puzzles.entries) {
          final source = (entry.value as Map)['sourceAsset'] as String;
          final codec = await ui.instantiateImageCodec(
            await File(source).readAsBytes(),
          );
          final frame = await codec.getNextFrame();
          result[entry.key] = (frame.image.width, frame.image.height);
          frame.image.dispose();
          codec.dispose();
        }
        return result;
      });

      for (final entry in sizes!.entries) {
        final (width, height) = entry.value;
        expect(width, height, reason: '${entry.key} kare değil');
        expect(width, 1200, reason: entry.key);
      }
    });
  });
}
