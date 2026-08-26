import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/card_collection.dart';
import 'package:game_app/cards/card_deck.dart';
import 'package:game_app/home_screen.dart';
import 'package:game_app/profile/player_profile.dart';
import 'package:game_app/settings/app_settings.dart';

import 'helpers.dart';

Future<void> pumpHome(
  WidgetTester tester, {
  CardCollection? collection,
  PlayerProfile? profile,
  AppSettings? settings,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapApp(
      const HomeScreen(),
      collection: collection,
      profile: profile,
      settings: settings,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Günlük oyun kartı', () {
    testWidgets('çubuk günlük oyun limitine göre dolar', (tester) async {
      await pumpHome(
        tester,
        settings: testSettings(dailyGameLimit: 5, playsToday: 2),
      );

      expect(find.text('Bugünün oyunları'), findsOneWidget);
      expect(find.text('Bugün 2 / 5 oyun oynadın'), findsOneWidget);
    });

    testWidgets('limit dolunca tamamlandı mesajı verir', (tester) async {
      await pumpHome(
        tester,
        settings: testSettings(dailyGameLimit: 3, playsToday: 3),
      );

      expect(find.text('Bugünlük oyunlar tamam!'), findsOneWidget);
    });

    testWidgets('kartta albümle ilgili bir şey yok', (tester) async {
      await pumpHome(
        tester,
        settings: testSettings(dailyGameLimit: 4, playsToday: 1),
      );

      final card = find.byKey(const ValueKey('home_daily_games'));
      expect(
        find.descendant(of: card, matching: find.textContaining('albüm')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.textContaining('kart')),
        findsNothing,
      );
    });
  });

  group('Bilgi albümü kartı', () {
    testWidgets('günlük karttan sonra gelir ve toplamı gösterir', (
      tester,
    ) async {
      await pumpHome(tester, collection: testCollection(collected: 3));

      expect(find.text('Bilgi albümüm'), findsOneWidget);
      expect(find.text('3 / ${cardDeck.length} kart toplandı'), findsOneWidget);

      // Sıralama: önce günlük oyun kartı, sonra albüm kartı.
      final daily = tester
          .getTopLeft(find.byKey(const ValueKey('home_daily_games')))
          .dy;
      final album = tester.getTopLeft(find.byKey(const ValueKey('home_album')));
      expect(album.dy, greaterThan(daily));
    });

    testWidgets('dokununca albüm açılır', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.byKey(const ValueKey('home_album')));
      await tester.pumpAndSettle();

      expect(find.text('Bilgi Albümü'), findsOneWidget);
    });

    testWidgets('tilki atölyesi kartı sayfada yok', (tester) async {
      await pumpHome(tester);

      expect(find.byKey(const ValueKey('home_workshop')), findsNothing);
      expect(find.text('Tilki Atölyesi'), findsNothing);
    });
  });

  group('Rozet kutlaması', () {
    testWidgets('rozet vitrini ana sayfada yok', (tester) async {
      await pumpHome(tester, collection: testCollection(collected: 1));

      expect(find.byKey(const ValueKey('home_badges')), findsNothing);
      expect(find.text('Rozetlerim'), findsNothing);
    });

    testWidgets('sayfa açılırken eldeki rozetler için pencere açılmaz', (
      tester,
    ) async {
      // "Meraklı Tilki" zaten kazanılmış durumda açılıyor.
      await pumpHome(tester, collection: testCollection(collected: 2));

      expect(find.text('Yeni rozet kazandın!'), findsNothing);
    });

    testWidgets('rozet kazanılınca kutlama penceresi düşer', (tester) async {
      final collection = CardCollection(collected: const []);
      await pumpHome(tester, collection: collection);

      expect(find.text('Yeni rozet kazandın!'), findsNothing);

      // İlk kart toplanınca "Meraklı Tilki" rozeti açılır.
      collection.save(cardDeck.first);
      await tester.pumpAndSettle();

      expect(find.text('Yeni rozet kazandın!'), findsOneWidget);
      expect(find.text('Meraklı Tilki'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('badge_unlocked_first_card')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('badge_unlocked_ok')));
      await tester.pumpAndSettle();

      expect(find.text('Yeni rozet kazandın!'), findsNothing);
    });

    testWidgets('aynı rozet ikinci kez kutlanmaz', (tester) async {
      final collection = CardCollection(collected: const []);
      await pumpHome(tester, collection: collection);

      collection.save(cardDeck.first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('badge_unlocked_ok')));
      await tester.pumpAndSettle();

      // Yeni kart rozeti açmıyor; pencere de tekrar gelmiyor.
      collection.save(cardDeck[1]);
      await tester.pumpAndSettle();

      expect(find.text('Yeni rozet kazandın!'), findsNothing);
    });
  });
}
