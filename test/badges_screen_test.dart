import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/badges/badge_catalog.dart';
import 'package:game_app/badges/badges_screen.dart';
import 'package:game_app/games/game_summary.dart';
import 'package:game_app/profile/player_profile.dart';

import 'helpers.dart';

/// Verilen sayıda oyunu oynanmış gibi işleyen profil.
PlayerProfile profileWith({int games = 0, int stars = 1, int points = 100}) {
  final profile = PlayerProfile();
  for (var i = 0; i < games; i++) {
    profile.recordGame(
      GameSummary(
        kind: GameKind.values[i % GameKind.values.length],
        points: points,
        stars: stars,
        elapsed: const Duration(minutes: 2),
      ),
    );
  }
  return profile;
}

Future<void> pumpBadges(
  WidgetTester tester, {
  PlayerProfile? profile,
  int collected = 0,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapApp(
      const BadgesScreen(),
      collection: testCollection(collected: collected, stars: 0),
      profile: profile ?? PlayerProfile(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Kilitli rozetlerdeki "3 / 10" biçimindeki ilerleme etiketleri.
Finder progressText(String text) => find.text(text);

void main() {
  testWidgets('boş profilde tüm rozetler kilitli görünür', (tester) async {
    await pumpBadges(tester);

    expect(find.text('Rozetlerim'), findsOneWidget);
    expect(
      find.byKey(ValueKey('badge_count_0_${badgeCatalog.length}')),
      findsOneWidget,
    );
    expect(find.text('Kazanıldı'), findsNothing);
    expect(find.byKey(const ValueKey('badge_first_game')), findsOneWidget);
    expect(progressText('0 / 1'), findsWidgets);
  });

  testWidgets('kazanılan rozet sayacı ve YENİ etiketi görünür', (tester) async {
    await pumpBadges(tester, profile: profileWith(games: 1), collected: 1);

    // İlk oyun + ilk kart rozeti kazanıldı.
    expect(
      find.byKey(ValueKey('badge_count_2_${badgeCatalog.length}')),
      findsOneWidget,
    );
    // Izgara sanallaştırıldığı için görünen kutulara bakılır.
    expect(find.text('Kazanıldı'), findsWidgets);
    expect(find.text('YENİ'), findsWidgets);
  });

  testWidgets('görülen rozet ikinci ziyarette YENİ değildir', (tester) async {
    final profile = profileWith(games: 1);

    await pumpBadges(tester, profile: profile);
    expect(find.text('YENİ'), findsOneWidget);

    // Sayfayı gerçekten kapatıp yeniden açmak için ağacı boşalt.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    // Aynı profille yeniden açıldığında etiket kalkar.
    await pumpBadges(tester, profile: profile);
    expect(find.text('YENİ'), findsNothing);
    expect(find.text('Kazanıldı'), findsOneWidget);
  });

  testWidgets('grup filtresi listeyi daraltır', (tester) async {
    await pumpBadges(tester);

    final chip = find.byKey(const ValueKey('badge_group_stil'));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('badge_first_item')), findsOneWidget);
    expect(find.byKey(const ValueKey('badge_first_game')), findsNothing);
  });

  testWidgets('rozete dokununca ayrıntı penceresi açılır', (tester) async {
    await pumpBadges(tester, profile: profileWith(games: 4));

    await tester.tap(find.byKey(const ValueKey('badge_ten_games')));
    await tester.pumpAndSettle();

    expect(find.text('10 oyun tamamla.'), findsOneWidget);
    expect(find.text('4 / 10'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('badge_close')));
    await tester.pumpAndSettle();
    expect(find.text('10 oyun tamamla.'), findsNothing);
  });

  testWidgets('özet kartı oyun ve yıldız sayısını gösterir', (tester) async {
    await pumpBadges(tester, profile: profileWith(games: 3, stars: 2));

    expect(find.text('Oynanan oyun'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('Toplam yıldız'), findsOneWidget);
    expect(find.text('6'), findsWidgets);
  });
}
