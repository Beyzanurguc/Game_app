import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_app/cards/card_collection.dart';
import 'package:game_app/cards/info_card.dart';
import 'package:game_app/profile/player_profile.dart';
import 'package:game_app/settings/app_settings.dart';
import 'package:game_app/settings/settings_storage.dart';
import 'package:game_app/games/yapboz/puzzle_catalog.dart';
import 'package:game_app/games/yapboz/puzzle_library.dart';
import 'package:game_app/theme/app_theme.dart';

import 'fixtures/test_cards.dart';
import 'fixtures/test_puzzles.dart';

/// Testlerde kullanılan koleksiyon: ilk [collected] kart açık, sabit tohum.
CardCollection testCollection({
  int collected = 2,
  int stars = 10,
  int seed = 1,
  List<InfoCard>? deck,
}) {
  final source = deck ?? testDeck;
  return CardCollection(
    deck: source,
    collected: source.take(collected).map((card) => card.id),
    stars: stars,
    random: Random(seed),
  );
}

/// Testlerde kullanılan ayarlar: giriş sayfası tamamlanmış, limit dolu.
AppSettings testSettings({
  String name = 'Beyza',
  int dailyGameLimit = maxDailyGameLimit,
  bool hapticsEnabled = true,
  int playsToday = 0,
  SettingsStorage? storage,
  DateTime Function()? clock,
}) {
  final now = clock ?? DateTime.now;
  final today = now();
  return AppSettings(
    state: StoredSettings(
      childName: name,
      dailyGameLimit: dailyGameLimit,
      hapticsEnabled: hapticsEnabled,
      onboarded: true,
      playDate:
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}',
      playsToday: playsToday,
    ),
    storage: storage,
    clock: clock,
  );
}

/// Ekranı koleksiyon, profil ve ayar kapsamları ile uygulama temasıyla sarar.
Widget wrapApp(
  Widget child, {
  CardCollection? collection,
  PlayerProfile? profile,
  AppSettings? settings,
  List<PuzzlePicture>? puzzles,
}) {
  return CardCollectionScope(
    collection: collection ?? testCollection(),
    child: PlayerProfileScope(
      profile: profile ?? PlayerProfile(),
      child: AppSettingsScope(
        settings: settings ?? testSettings(),
        child: PuzzleLibraryScope(
          pictures: puzzles ?? testPuzzles,
          child: MaterialApp(theme: buildAppTheme(), home: child),
        ),
      ),
    ),
  );
}

/// Ekrandaki yetişkin kapısını yanıtlayıp geçer.
///
/// Soru rastgele üretildiği için yanıt testte sabitlenemez; pencerede yazan
/// çarpım okunup hesaplanır.
Future<void> passParentGate(WidgetTester tester) async {
  final question = tester.widget<Text>(
    find.byKey(const ValueKey('parent_gate_question')),
  );
  final numbers = RegExp(r'\d+')
      .allMatches(question.data ?? '')
      .map((match) => int.parse(match[0]!))
      .toList();

  await tester.enterText(
    find.byKey(const ValueKey('parent_gate_answer')),
    '${numbers[0] * numbers[1]}',
  );
  await tester.tap(find.byKey(const ValueKey('parent_gate_submit')));
  await tester.pumpAndSettle();
}
