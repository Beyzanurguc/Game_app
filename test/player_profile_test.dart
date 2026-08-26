import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/games/game_summary.dart';
import 'package:game_app/profile/fox_items.dart';
import 'package:game_app/profile/player_profile.dart';
import 'package:game_app/profile/profile_storage.dart';

GameSummary summary(GameKind kind, {int points = 100, int stars = 2}) =>
    GameSummary(
      kind: kind,
      points: points,
      stars: stars,
      elapsed: const Duration(minutes: 1),
    );

FoxItem itemOf(String id) => foxItems.firstWhere((item) => item.id == id);

void main() {
  group('istatistikler', () {
    test('biten oyun kayıtlara işlenir', () {
      final profile = PlayerProfile();

      profile.recordGame(summary(GameKind.tetris, points: 400, stars: 1));
      profile.recordGame(summary(GameKind.tetris, points: 250, stars: 3));

      final record = profile.recordOf(GameKind.tetris);
      expect(record.plays, 2);
      expect(record.bestScore, 400, reason: 'en iyi skor düşmemeli');
      expect(record.totalPoints, 650);
      expect(profile.gamesPlayed, 2);
      expect(profile.totalStarsEarned, 4);
    });

    test('farklı oyunlar ayrı sayılır', () {
      final profile = PlayerProfile();

      profile.recordGame(summary(GameKind.sudoku));
      profile.recordGame(summary(GameKind.blok));
      profile.recordGame(summary(GameKind.blok));

      expect(profile.recordOf(GameKind.sudoku).plays, 1);
      expect(profile.recordOf(GameKind.blok).plays, 2);
      expect(profile.recordOf(GameKind.tetris).plays, 0);
      expect(profile.gamesPlayedAtLeast(2), 1);
      expect(profile.gamesPlayed, 3);
    });
  });

  group('gardırop', () {
    test('alınan aksesuar hemen takılır', () {
      final profile = PlayerProfile();
      final beanie = itemOf('beanie');

      expect(profile.unlock(beanie), isTrue);
      expect(profile.owns('beanie'), isTrue);
      expect(profile.isEquipped(beanie), isTrue);
      expect(profile.equippedItems, [beanie]);

      // İkinci kez alınamaz.
      expect(profile.unlock(beanie), isFalse);
      expect(profile.ownedCount, 1);
    });

    test('aynı bölgedeki ikinci aksesuar öncekinin yerini alır', () {
      final profile = PlayerProfile();
      final beanie = itemOf('beanie');
      final crown = itemOf('crown');

      profile.unlock(beanie);
      profile.unlock(crown);

      expect(profile.equippedIn(FoxSlot.hat), crown);
      expect(profile.equippedItems.length, 1);
      expect(profile.ownedCount, 2, reason: 'ikisi de gardıropta kalır');
    });

    test('farklı bölgeler aynı anda takılabilir', () {
      final profile = PlayerProfile()
        ..unlock(itemOf('beanie'))
        ..unlock(itemOf('round_glasses'))
        ..unlock(itemOf('scarf'));

      expect(profile.equippedItems.length, 3);
    });

    test('takılı aksesuara dokunmak onu çıkarır', () {
      final profile = PlayerProfile();
      final beanie = itemOf('beanie');
      profile.unlock(beanie);

      profile.toggleEquip(beanie);
      expect(profile.isEquipped(beanie), isFalse);
      expect(profile.owns('beanie'), isTrue);

      profile.toggleEquip(beanie);
      expect(profile.isEquipped(beanie), isTrue);

      profile.clearSlot(FoxSlot.hat);
      expect(profile.equippedItems, isEmpty);
    });

    test('sahip olunmayan aksesuar takılamaz', () {
      final profile = PlayerProfile();

      profile.toggleEquip(itemOf('crown'));

      expect(profile.equippedItems, isEmpty);
    });
  });

  group('rozet işaretleri', () {
    test('görülen rozetler saklanır', () {
      final profile = PlayerProfile();

      profile.markBadgesSeen(['first_game', 'ten_games']);

      expect(profile.hasSeenBadge('first_game'), isTrue);
      expect(profile.hasSeenBadge('ten_games'), isTrue);
      expect(profile.hasSeenBadge('all_cards'), isFalse);
    });
  });

  group('kalıcılık', () {
    test('değişiklikler diske yazılır ve geri okunur', () async {
      final storage = MemoryProfileStorage();
      final profile = PlayerProfile(storage: storage);

      profile.recordGame(summary(GameKind.blok, points: 900, stars: 4));
      profile.unlock(itemOf('bow_tie'));
      profile.markBadgesSeen(['first_game']);
      await profile.pending;

      expect(storage.writes, 3);

      final restored = await PlayerProfile.restore(storage: storage);
      expect(restored.totalStarsEarned, 4);
      expect(restored.recordOf(GameKind.blok).bestScore, 900);
      expect(restored.owns('bow_tie'), isTrue);
      expect(restored.equippedIn(FoxSlot.neck)?.id, 'bow_tie');
      expect(restored.hasSeenBadge('first_game'), isTrue);
    });

    test('bozuk kayıt oyunu çökertmez', () {
      expect(StoredProfile.decode('{bozuk json').totalStarsEarned, 0);
      expect(StoredProfile.decode(null).owned, isEmpty);
    });

    test('sıfırlama her şeyi temizler', () {
      final profile = PlayerProfile()
        ..recordGame(summary(GameKind.tetris))
        ..unlock(itemOf('beanie'))
        ..reset();

      expect(profile.gamesPlayed, 0);
      expect(profile.totalStarsEarned, 0);
      expect(profile.ownedCount, 0);
      expect(profile.equippedItems, isEmpty);
    });
  });
}
