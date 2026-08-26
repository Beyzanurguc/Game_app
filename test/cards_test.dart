import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/album_screen.dart';
import 'package:game_app/cards/card_collection.dart';
import 'package:game_app/cards/card_deck.dart';
import 'package:game_app/cards/info_card.dart';
import 'package:game_app/cards/reward_card_screen.dart';
import 'package:game_app/games/game_summary.dart';

import 'helpers.dart';

const _summary = GameSummary(
  kind: GameKind.sudoku,
  points: 240,
  stars: 2,
  elapsed: Duration(minutes: 4, seconds: 3),
  stats: [
    GameStat(
      icon: Icons.local_fire_department_rounded,
      label: 'En uzun seri',
      value: '7',
    ),
    GameStat(icon: Icons.close_rounded, label: 'Hata', value: '1'),
  ],
);

Future<void> pumpReward(
  WidgetTester tester,
  CardCollection collection, {
  InfoCard? card,
  bool isNew = true,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapApp(
      RewardCardScreen(
        card: card ?? collection.drawReward().card,
        isNew: isNew,
        summary: _summary,
      ),
      collection: collection,
    ),
  );
  await tester.pumpAndSettle();
}

/// Liste içinde aşağıda kalan bir öğeyi görünür hâle getirir.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Kart destesi', () {
    test('her kartın kimliği tekil ve içeriği dolu', () {
      final ids = cardDeck.map((card) => card.id).toSet();
      expect(ids.length, cardDeck.length);

      for (final card in cardDeck) {
        expect(card.title, isNotEmpty, reason: card.id);
        expect(card.question, isNotEmpty, reason: card.id);
        expect(card.answer, isNotEmpty, reason: card.id);
        expect(card.facts, isNotEmpty, reason: card.id);
        expect(card.emoji, isNotEmpty, reason: card.id);
      }
    });

    test('her kategoride en az bir kart var', () {
      for (final category in CardCategory.values) {
        expect(
          cardDeck.where((card) => card.category == category),
          isNotEmpty,
          reason: category.label,
        );
      }
    });

    test('deste 100 kart ve çevre ağırlıklı', () {
      expect(cardDeck.length, 100);

      final cevre = cardDeck
          .where((card) => card.category == CardCategory.cevre)
          .length;
      for (final category in CardCategory.values) {
        if (category == CardCategory.cevre) continue;
        expect(
          cardDeck.where((card) => card.category == category).length,
          lessThan(cevre),
          reason: category.label,
        );
      }
    });
  });

  group('CardCollection', () {
    test('ilerleme toplanan kart sayısını yansıtır', () {
      final collection = testCollection(collected: 3);

      expect(collection.collectedCount, 3);
      expect(collection.total, cardDeck.length);
      expect(collection.progress, 3 / cardDeck.length);
      expect(collection.isCollected(cardDeck.first.id), isTrue);
      expect(collection.isCollected(cardDeck.last.id), isFalse);
    });

    test('drawReward toplanmamış bir kartı yeni olarak verir', () {
      final collection = CardCollection(
        collected: cardDeck.take(cardDeck.length - 1).map((c) => c.id),
        random: Random(1),
      );

      final draw = collection.drawReward();
      expect(draw.card.id, cardDeck.last.id);
      expect(draw.isNew, isTrue);
      expect(collection.isComplete, isFalse);
    });

    test('deste bitince kart tekrar bilgisi olarak döner', () {
      final collection = CardCollection(
        collected: cardDeck.map((c) => c.id),
        random: Random(1),
      );

      final draw = collection.drawReward();
      expect(collection.isComplete, isTrue);
      expect(draw.isNew, isFalse);
      expect(collection.isCollected(draw.card.id), isTrue);
    });

    test('save aynı kartı iki kez eklemez ve dinleyicileri uyarır', () {
      final collection = testCollection(collected: 0);
      var notifications = 0;
      collection.addListener(() => notifications++);

      expect(collection.save(cardDeck.first), isTrue);
      expect(collection.save(cardDeck.first), isFalse);
      expect(collection.collectedCount, 1);
      expect(notifications, 1);
    });

    test('addStars yıldızı artırır, negatif değeri yok sayar', () {
      final collection = testCollection(stars: 5);

      collection.addStars(3);
      expect(collection.stars, 8);

      collection.addStars(-2);
      expect(collection.stars, 8);
    });

    test('byCategory yalnızca o kategorinin kartlarını verir', () {
      final collection = testCollection();
      final uzay = collection.byCategory(CardCategory.uzay);

      expect(uzay, isNotEmpty);
      expect(uzay.every((c) => c.category == CardCategory.uzay), isTrue);
      expect(collection.byCategory(null).length, cardDeck.length);
    });
  });

  group('Ödül ekranı', () {
    testWidgets('skor, kart ve butonlar görünür', (tester) async {
      final collection = testCollection();
      final card = cardDeck.last;
      await pumpReward(tester, collection, card: card);

      expect(find.text('Skorun: 240'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text(card.question), findsOneWidget);
      expect(find.text('KARTI KAYDET'), findsOneWidget);
      expect(find.text('TEKRAR OYNA'), findsOneWidget);
    });

    testWidgets('"Biraz daha anlat" bilgileri açar', (tester) async {
      final collection = testCollection();
      final card = cardDeck.last;
      await pumpReward(tester, collection, card: card);

      expect(find.text('Biliyor muydun?'), findsNothing);

      await scrollTo(tester, find.text('Biraz daha anlat'));
      await tester.tap(find.text('Biraz daha anlat'));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('Biliyor muydun?'));

      expect(find.text('Biliyor muydun?'), findsOneWidget);
      expect(find.text(card.facts.first), findsOneWidget);
    });

    testWidgets('Kartı Kaydet kartı albüme ekler', (tester) async {
      final collection = testCollection();
      final card = cardDeck.last;
      await pumpReward(tester, collection, card: card);

      expect(collection.isCollected(card.id), isFalse);

      await tester.tap(find.text('KARTI KAYDET'));
      await tester.pumpAndSettle();

      expect(collection.isCollected(card.id), isTrue);
      expect(find.text('Albümüne eklendi'), findsOneWidget);
      expect(find.text('ANA SAYFA'), findsOneWidget);
    });

    testWidgets('kaydetmeden çıkarken uyarı gelir, "Kartı Al" kaydeder', (
      tester,
    ) async {
      final collection = testCollection();
      final card = cardDeck.last;
      await pumpReward(tester, collection, card: card);

      await tester.tap(find.byKey(const ValueKey('reward_close')));
      await tester.pumpAndSettle();

      expect(find.text('Kartını almadan çıkıyorsun'), findsOneWidget);
      expect(find.text('Bu kart albümüne eklenmeyecek.'), findsOneWidget);

      await tester.tap(find.text('KARTI AL'));
      await tester.pumpAndSettle();

      expect(collection.isCollected(card.id), isTrue);
      expect(find.text('ANA SAYFA'), findsOneWidget); // ekranda kalır
    });

    testWidgets('deste bitince yeni kart yerine tekrar bilgisi gösterilir', (
      tester,
    ) async {
      final collection = CardCollection(
        collected: cardDeck.map((c) => c.id),
        random: Random(1),
      );
      final draw = collection.drawReward();
      await pumpReward(tester, collection, card: draw.card, isNew: draw.isNew);

      expect(find.text('Yeni kartlar yakında yüklenecek'), findsOneWidget);
      expect(find.text('Yeni kart!'), findsNothing);
      expect(find.text('Albümünde vardı'), findsOneWidget);
      expect(find.text('KARTI KAYDET'), findsNothing);
      expect(find.text('ANA SAYFA'), findsOneWidget);
      // Eski kartın bilgisi yine okunabiliyor.
      expect(find.text(draw.card.question), findsOneWidget);
    });

    testWidgets('deste bitince çıkışta uyarı gösterilmez', (tester) async {
      final collection = CardCollection(
        collected: cardDeck.map((c) => c.id),
        random: Random(1),
      );
      await pumpReward(tester, collection, card: cardDeck.first, isNew: false);

      await tester.tap(find.byKey(const ValueKey('reward_close')));
      await tester.pumpAndSettle();

      expect(find.text('Kartını almadan çıkıyorsun'), findsNothing);
    });

    testWidgets('kaydettikten sonra çıkışta uyarı gösterilmez', (tester) async {
      final collection = testCollection();
      await pumpReward(tester, collection, card: cardDeck.last);

      await tester.tap(find.text('KARTI KAYDET'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('reward_close')));
      await tester.pumpAndSettle();

      expect(find.text('Kartını almadan çıkıyorsun'), findsNothing);
    });
  });

  group('Albüm', () {
    testWidgets('toplanan kartlar açık, diğerleri kilitli görünür', (
      tester,
    ) async {
      final collection = testCollection(collected: 2);
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrapApp(const AlbumScreen(), collection: collection),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bilgi Albümü'), findsOneWidget);
      expect(
        find.text('${collection.collectedCount} / ${collection.total} kart'),
        findsOneWidget,
      );
      expect(find.text(cardDeck[0].title), findsOneWidget);
      expect(find.text('???'), findsWidgets); // kilitli kartlar
    });

    testWidgets('kilitli karta dokununca bilgi mesajı çıkar', (tester) async {
      final collection = testCollection(collected: 1);
      await tester.pumpWidget(
        wrapApp(const AlbumScreen(), collection: collection),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('album_${cardDeck[3].id}')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Bu kartı oyun oynayarak kazanabilirsin!'),
        findsOneWidget,
      );
    });

    testWidgets('açık karta dokununca detay ekranı açılır', (tester) async {
      final collection = testCollection(collected: 1);
      await tester.pumpWidget(
        wrapApp(const AlbumScreen(), collection: collection),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('album_${cardDeck[0].id}')));
      await tester.pumpAndSettle();
      await scrollTo(tester, find.text('HARİKA, ÖĞRENDİM!'));

      expect(find.text('Biliyor muydun?'), findsOneWidget);
      expect(find.text('HARİKA, ÖĞRENDİM!'), findsOneWidget);

      await tester.tap(find.text('HARİKA, ÖĞRENDİM!'));
      await tester.pumpAndSettle();

      expect(find.text('Bilgi Albümü'), findsOneWidget); // albüme döner
    });

    testWidgets('kategori filtresi listeyi daraltır', (tester) async {
      final collection = CardCollection(
        collected: cardDeck.map((c) => c.id),
        random: Random(1),
      );
      await tester.pumpWidget(
        wrapApp(const AlbumScreen(), collection: collection),
      );
      await tester.pumpAndSettle();

      final hayvanlar = collection.byCategory(CardCategory.hayvanlar);
      await tester.tap(find.text('Hayvanlar').last);
      await tester.pumpAndSettle();

      expect(find.text(hayvanlar.first.title), findsOneWidget);
      final uzayCard = collection.byCategory(CardCategory.uzay).first;
      expect(find.text(uzayCard.title), findsNothing);
    });
  });
}
