import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/card_collection.dart';
import 'package:game_app/cards/card_storage.dart';
import 'package:game_app/cards/reward_card_screen.dart';
import 'package:game_app/games/game_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/test_cards.dart';
import 'helpers.dart';

const _summary = GameSummary(
  kind: GameKind.sudoku,
  points: 120,
  stars: 1,
  elapsed: Duration(minutes: 2),
);

void main() {
  group('MemoryCardStorage ile koleksiyon', () {
    test('restore kayıtlı durumu geri yükler', () async {
      final storage = MemoryCardStorage(
        collected: {testDeck[0].id, testDeck[1].id},
        stars: 12,
      );

      final collection = await CardCollection.restore(deck: testDeck, storage: storage);

      expect(collection.collectedCount, 2);
      expect(collection.stars, 12);
      expect(collection.isCollected(testDeck[0].id), isTrue);
      expect(collection.isCollected(testDeck[5].id), isFalse);
    });

    test('kart kaydetmek diske yazar', () async {
      final storage = MemoryCardStorage();
      final collection = await CardCollection.restore(deck: testDeck, storage: storage);

      collection.save(testDeck.first);
      await collection.pending;

      expect(storage.writes, 1);
      expect((await storage.load()).collected, {testDeck.first.id});
    });

    test('aynı kart ikinci kez kaydedilince tekrar yazılmaz', () async {
      final storage = MemoryCardStorage();
      final collection = await CardCollection.restore(deck: testDeck, storage: storage);

      collection.save(testDeck.first);
      collection.save(testDeck.first);
      await collection.pending;

      expect(storage.writes, 1);
    });

    test('yıldızlar diske yazılır', () async {
      final storage = MemoryCardStorage(stars: 4);
      final collection = await CardCollection.restore(deck: testDeck, storage: storage);

      collection.addStars(6);
      await collection.pending;

      expect((await storage.load()).stars, 10);
    });

    test('reset hem belleği hem diski temizler', () async {
      final storage = MemoryCardStorage(collected: {testDeck[0].id}, stars: 30);
      final collection = await CardCollection.restore(deck: testDeck, storage: storage);

      collection.reset();
      await collection.pending;

      expect(collection.collectedCount, 0);
      expect(collection.stars, 0);
      final stored = await storage.load();
      expect(stored.collected, isEmpty);
      expect(stored.stars, 0);
    });

    test('depo verilmezse yalnızca bellekte tutulur', () {
      final collection = CardCollection(deck: testDeck, random: Random(1));

      collection.save(testDeck.first);
      collection.addStars(5);

      expect(collection.collectedCount, 1);
      expect(collection.stars, 5);
    });
  });

  group('SharedPreferences ile koleksiyon', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('ilk açılışta boş başlar', () async {
      final collection = await CardCollection.restore(
      deck: testDeck,
        storage: SharedPreferencesCardStorage(),
      );

      expect(collection.collectedCount, 0);
      expect(collection.stars, 0);
    });

    test('yazılan ilerleme sonraki açılışta geri gelir', () async {
      final first = await CardCollection.restore(
      deck: testDeck,
        storage: SharedPreferencesCardStorage(),
      );
      first.save(testDeck[2]);
      first.addStars(7);
      await first.pending;

      // Yeni bir oturum: aynı diskten okuyan yeni koleksiyon.
      final second = await CardCollection.restore(
      deck: testDeck,
        storage: SharedPreferencesCardStorage(),
      );

      expect(second.isCollected(testDeck[2].id), isTrue);
      expect(second.stars, 7);
    });
  });

  group('Ödül ekranı kalıcılığı', () {
    testWidgets('kaydedilen kart diske yazılır', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = SharedPreferencesCardStorage();
      final collection = await CardCollection.restore(deck: testDeck, storage: storage);
      final card = testDeck.last;

      await tester.pumpWidget(
        wrapApp(
          RewardCardScreen(card: card, summary: _summary),
          collection: collection,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('KARTI KAYDET'));
      await tester.pumpAndSettle();
      await collection.pending;

      expect((await storage.load()).collected, contains(card.id));
    });
  });
}
