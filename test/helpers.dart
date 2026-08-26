import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_app/cards/card_collection.dart';
import 'package:game_app/cards/card_deck.dart';
import 'package:game_app/profile/player_profile.dart';
import 'package:game_app/settings/app_settings.dart';
import 'package:game_app/settings/settings_storage.dart';
import 'package:game_app/theme/app_theme.dart';

/// Testlerde kullanılan koleksiyon: ilk [collected] kart açık, sabit tohum.
CardCollection testCollection({
  int collected = 2,
  int stars = 10,
  int seed = 1,
}) {
  return CardCollection(
    collected: cardDeck.take(collected).map((card) => card.id),
    stars: stars,
    random: Random(seed),
  );
}

/// Testlerde kullanılan ayarlar: giriş sayfası tamamlanmış, limit dolu.
AppSettings testSettings({
  String name = 'Beyza',
  int dailyGameLimit = maxDailyGameLimit,
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
}) {
  return CardCollectionScope(
    collection: collection ?? testCollection(),
    child: PlayerProfileScope(
      profile: profile ?? PlayerProfile(),
      child: AppSettingsScope(
        settings: settings ?? testSettings(),
        child: MaterialApp(theme: buildAppTheme(), home: child),
      ),
    ),
  );
}
