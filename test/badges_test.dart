import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/badges/badge_catalog.dart';
import 'package:game_app/cards/card_deck.dart';
import 'package:game_app/games/game_summary.dart';
import 'package:game_app/profile/fox_items.dart';
import 'package:game_app/profile/player_profile.dart';

import 'helpers.dart';

BadgeStatus statusOf(BadgeContext context, String id) =>
    evaluateBadges(context).firstWhere((status) => status.def.id == id);

BadgeContext contextWith({PlayerProfile? profile, int collected = 0}) =>
    BadgeContext(
      profile: profile ?? PlayerProfile(),
      collection: testCollection(collected: collected, stars: 0),
    );

void main() {
  test('boş profilde hiçbir rozet kazanılmamıştır', () {
    final all = evaluateBadges(contextWith());

    expect(all.length, badgeCatalog.length);
    expect(all.every((status) => !status.earned), isTrue);
    expect(earnedBadges(contextWith()), isEmpty);
  });

  test('ilk oyun rozeti tek turda açılır', () {
    final profile = PlayerProfile()
      ..recordGame(
        const GameSummary(
          kind: GameKind.tetris,
          points: 120,
          stars: 1,
          elapsed: Duration(minutes: 2),
        ),
      );
    final context = contextWith(profile: profile);

    expect(statusOf(context, 'first_game').earned, isTrue);
    expect(statusOf(context, 'ten_games').earned, isFalse);
    expect(statusOf(context, 'ten_games').progress, 1);
    expect(statusOf(context, 'ten_games').target, 10);
  });

  test('oyuna özel rozetler en iyi skora bakar', () {
    final profile = PlayerProfile()
      ..recordGame(
        const GameSummary(
          kind: GameKind.blok,
          points: 2400,
          stars: 5,
          elapsed: Duration(minutes: 6),
        ),
      );
    final context = contextWith(profile: profile);

    expect(statusOf(context, 'blok_pro').earned, isTrue);
    expect(
      statusOf(context, 'tetris_pro').earned,
      isFalse,
      reason: 'başka oyunun skoru sayılmamalı',
    );
  });

  test('üç oyunu da oynamak "Her Oyundan Tat" rozetini açar', () {
    final profile = PlayerProfile();
    for (final kind in GameKind.values) {
      for (var i = 0; i < 3; i++) {
        profile.recordGame(
          GameSummary(
            kind: kind,
            points: 50,
            stars: 1,
            elapsed: const Duration(minutes: 1),
          ),
        );
      }
    }
    final context = contextWith(profile: profile);

    expect(statusOf(context, 'all_games').earned, isTrue);
    expect(statusOf(context, 'ten_games').earned, isFalse, reason: '9 oyun');
  });

  test('kart rozetlerinin hedefi deste uzunluğudur', () {
    final context = contextWith(collected: cardDeck.length);

    expect(statusOf(context, 'all_cards').target, cardDeck.length);
    expect(statusOf(context, 'all_cards').earned, isTrue);
    expect(statusOf(context, 'first_card').earned, isTrue);
  });

  test('yıldız rozeti harcamadan etkilenmez', () {
    final profile = PlayerProfile();
    for (var i = 0; i < 10; i++) {
      profile.recordGame(
        const GameSummary(
          kind: GameKind.sudoku,
          points: 100,
          stars: 5,
          elapsed: Duration(minutes: 3),
        ),
      );
    }
    final collection = testCollection(stars: 0);
    final context = BadgeContext(profile: profile, collection: collection);

    // Bakiye sıfır ama toplam kazanç 50.
    expect(collection.stars, 0);
    expect(statusOf(context, 'stars_50').earned, isTrue);
  });

  test('aksesuar rozetleri gardıropla ilerler', () {
    final profile = PlayerProfile();
    for (final item in foxItems.take(5)) {
      profile.unlock(item);
    }
    final context = contextWith(profile: profile);

    expect(statusOf(context, 'first_item').earned, isTrue);
    expect(statusOf(context, 'five_items').earned, isTrue);
    expect(statusOf(context, 'five_items').ratio, 1);
  });

  test('ilerleme oranı 0-1 arasında kalır', () {
    final profile = PlayerProfile()
      ..recordGame(
        const GameSummary(
          kind: GameKind.tetris,
          points: 5000,
          stars: 5,
          elapsed: Duration(minutes: 9),
        ),
      );
    final status = statusOf(contextWith(profile: profile), 'tetris_pro');

    expect(status.progress, 5000);
    expect(status.ratio, 1);
  });
}
