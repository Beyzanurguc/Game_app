import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tek bir oyunun birikmiş istatistiği.
class GameRecord {
  const GameRecord({this.plays = 0, this.bestScore = 0, this.totalPoints = 0});

  /// Kaç kez oynandı.
  final int plays;

  /// Tek turdaki en yüksek puan.
  final int bestScore;

  /// Tüm turların puan toplamı.
  final int totalPoints;

  GameRecord withResult(int points) => GameRecord(
    plays: plays + 1,
    bestScore: points > bestScore ? points : bestScore,
    totalPoints: totalPoints + points,
  );

  Map<String, dynamic> toJson() => {
    'plays': plays,
    'best': bestScore,
    'points': totalPoints,
  };

  static GameRecord fromJson(Map<String, dynamic> json) => GameRecord(
    plays: _int(json['plays']),
    bestScore: _int(json['best']),
    totalPoints: _int(json['points']),
  );
}

/// Diskten okunan/yazılan oyuncu profili.
class StoredProfile {
  const StoredProfile({
    this.totalStarsEarned = 0,
    this.records = const {},
    this.owned = const {},
    this.equipped = const {},
    this.seenBadges = const {},
  });

  /// Bugüne kadar kazanılan toplam yıldız — harcansa da azalmaz.
  final int totalStarsEarned;

  /// Oyun kimliği (GameKind.name) -> istatistik.
  final Map<String, GameRecord> records;

  /// Satın alınmış aksesuar kimlikleri.
  final Set<String> owned;

  /// Bölge (FoxSlot.name) -> takılı aksesuar kimliği.
  final Map<String, String> equipped;

  /// Oyuncunun rozet sayfasında görmüş olduğu rozetler; yeni kazanılanı
  /// işaretlemek için tutulur.
  final Set<String> seenBadges;

  Map<String, dynamic> toJson() => {
    'totalStars': totalStarsEarned,
    'records': {
      for (final entry in records.entries) entry.key: entry.value.toJson(),
    },
    'owned': owned.toList(),
    'equipped': equipped,
    'seenBadges': seenBadges.toList(),
  };

  static StoredProfile fromJson(Map<String, dynamic> json) => StoredProfile(
    totalStarsEarned: _int(json['totalStars']),
    records: {
      for (final entry in _map(json['records']).entries)
        entry.key: GameRecord.fromJson(_map(entry.value)),
    },
    owned: _strings(json['owned']).toSet(),
    equipped: {
      for (final entry in _map(json['equipped']).entries)
        entry.key: '${entry.value}',
    },
    seenBadges: _strings(json['seenBadges']).toSet(),
  );

  String encode() => jsonEncode(toJson());

  /// Bozuk ya da eski biçimli kayıt oyunu çökertmez; boş profile düşer.
  static StoredProfile decode(String? raw) {
    if (raw == null || raw.isEmpty) return const StoredProfile();
    try {
      return StoredProfile.fromJson(_map(jsonDecode(raw)));
    } catch (error) {
      debugPrint('Profil kaydı okunamadı ($error); sıfırdan başlanıyor.');
      return const StoredProfile();
    }
  }
}

int _int(Object? value) => value is int ? value : 0;

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const {};

List<String> _strings(Object? value) =>
    value is List ? value.map((item) => '$item').toList() : const [];

/// Profilin kalıcı kaydı. Test ve farklı platformlar için soyutlandı.
abstract interface class ProfileStorage {
  Future<StoredProfile> load();

  Future<void> persist(StoredProfile profile);
}

/// `shared_preferences` tabanlı kalıcı kayıt.
///
/// [SharedPreferencesCardStorage] ile aynı savunmacı yaklaşım: eklenti
/// kullanılamıyorsa kayıt o oturumda yalnızca bellekte kalır.
class SharedPreferencesProfileStorage implements ProfileStorage {
  SharedPreferencesProfileStorage();

  static const _profileKey = 'player_profile';

  SharedPreferences? _prefs;
  bool _available = true;

  Future<SharedPreferences?> get _instance async {
    if (!_available) return null;
    try {
      return _prefs ??= await SharedPreferences.getInstance();
    } catch (error) {
      _available = false;
      debugPrint('Profil kaydı kullanılamıyor ($error).');
      return null;
    }
  }

  @override
  Future<StoredProfile> load() async {
    final prefs = await _instance;
    if (prefs == null) return const StoredProfile();
    return StoredProfile.decode(prefs.getString(_profileKey));
  }

  @override
  Future<void> persist(StoredProfile profile) async {
    final prefs = await _instance;
    if (prefs == null) return;

    try {
      await prefs.setString(_profileKey, profile.encode());
    } catch (error) {
      debugPrint('Profil kaydedilemedi: $error');
    }
  }
}

/// Testler için bellek içi kayıt.
class MemoryProfileStorage implements ProfileStorage {
  MemoryProfileStorage([this._profile = const StoredProfile()]);

  StoredProfile _profile;

  /// Kaç kez diske yazıldığı — testler bunu kontrol eder.
  int writes = 0;

  StoredProfile get current => _profile;

  @override
  Future<StoredProfile> load() async => _profile;

  @override
  Future<void> persist(StoredProfile profile) async {
    _profile = profile;
    writes++;
  }
}
