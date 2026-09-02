import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Günlük oyun limitinin izin verilen aralığı.
///
/// Giriş sayfasındaki sürgü de bu sınırları kullanır; tek yerden değişir.
const int minDailyGameLimit = 1;
const int maxDailyGameLimit = 20;
const int defaultDailyGameLimit = 5;

/// Ad kutusunun karakter sınırı.
const int maxChildNameLength = 50;

/// Giriş sayfasında toplanan ve diskte tutulan ayarlar.
///
/// Bilerek küçük tutuldu: yalnızca çocuğun adı, günlük oyun limiti ve limitin
/// takibi için bugünkü tur sayacı.
class StoredSettings {
  const StoredSettings({
    this.childName = '',
    this.dailyGameLimit = defaultDailyGameLimit,
    this.hapticsEnabled = true,
    this.onboarded = false,
    this.playDate = '',
    this.playsToday = 0,
  });

  /// Çocuğun adı; giriş sayfasında boş bırakılabilir.
  final String childName;

  /// Günde başlanabilecek en fazla tur sayısı.
  final int dailyGameLimit;

  /// Oyunlardaki titreşim geri bildirimi açık mı? Varsayılan açık.
  final bool hapticsEnabled;

  /// Giriş sayfası tamamlandı mı? False ise uygulama oraya açılır.
  final bool onboarded;

  /// [playsToday] hangi güne ait (yyyy-aa-gg). Gün değişince sayaç sıfırlanır.
  final String playDate;

  /// [playDate] günü içinde başlanan tur sayısı.
  final int playsToday;

  StoredSettings copyWith({
    String? childName,
    int? dailyGameLimit,
    bool? hapticsEnabled,
    bool? onboarded,
    String? playDate,
    int? playsToday,
  }) => StoredSettings(
    childName: childName ?? this.childName,
    dailyGameLimit: dailyGameLimit ?? this.dailyGameLimit,
    hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    onboarded: onboarded ?? this.onboarded,
    playDate: playDate ?? this.playDate,
    playsToday: playsToday ?? this.playsToday,
  );

  Map<String, dynamic> toJson() => {
    'name': childName,
    'limit': dailyGameLimit,
    'haptics': hapticsEnabled,
    'onboarded': onboarded,
    'playDate': playDate,
    'plays': playsToday,
  };

  static StoredSettings fromJson(Map<String, dynamic> json) => StoredSettings(
    childName: json['name'] is String ? json['name'] as String : '',
    dailyGameLimit: _limit(json['limit']),
    // Ayar eklenmeden önce kaydedilmiş dosyalarda alan yok; açık sayılır.
    hapticsEnabled: json['haptics'] is bool ? json['haptics'] as bool : true,
    onboarded: json['onboarded'] == true,
    playDate: json['playDate'] is String ? json['playDate'] as String : '',
    playsToday: json['plays'] is int ? json['plays'] as int : 0,
  );

  String encode() => jsonEncode(toJson());

  /// Bozuk ya da eski biçimli kayıt oyunu çökertmez; varsayılana düşer.
  static StoredSettings decode(String? raw) {
    if (raw == null || raw.isEmpty) return const StoredSettings();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const StoredSettings();
      return StoredSettings.fromJson(decoded.cast<String, dynamic>());
    } catch (error) {
      debugPrint('Ayar kaydı okunamadı ($error); varsayılana dönülüyor.');
      return const StoredSettings();
    }
  }
}

int _limit(Object? value) => value is int
    ? value.clamp(minDailyGameLimit, maxDailyGameLimit)
    : defaultDailyGameLimit;

/// Ayarların kalıcı kaydı. Test ve farklı platformlar için soyutlandı.
abstract interface class SettingsStorage {
  Future<StoredSettings> load();

  Future<void> persist(StoredSettings settings);
}

/// `shared_preferences` tabanlı kalıcı kayıt.
///
/// Diğer depolarla aynı savunmacı yaklaşım: eklenti kullanılamıyorsa kayıt o
/// oturumda yalnızca bellekte kalır.
class SharedPreferencesSettingsStorage implements SettingsStorage {
  SharedPreferencesSettingsStorage();

  static const _settingsKey = 'app_settings';

  SharedPreferences? _prefs;
  bool _available = true;

  Future<SharedPreferences?> get _instance async {
    if (!_available) return null;
    try {
      return _prefs ??= await SharedPreferences.getInstance();
    } catch (error) {
      _available = false;
      debugPrint('Ayar kaydı kullanılamıyor ($error).');
      return null;
    }
  }

  @override
  Future<StoredSettings> load() async {
    final prefs = await _instance;
    if (prefs == null) return const StoredSettings();
    return StoredSettings.decode(prefs.getString(_settingsKey));
  }

  @override
  Future<void> persist(StoredSettings settings) async {
    final prefs = await _instance;
    if (prefs == null) return;

    try {
      await prefs.setString(_settingsKey, settings.encode());
    } catch (error) {
      debugPrint('Ayarlar kaydedilemedi: $error');
    }
  }
}

/// Testler için bellek içi kayıt.
class MemorySettingsStorage implements SettingsStorage {
  MemorySettingsStorage([this._settings = const StoredSettings()]);

  StoredSettings _settings;

  /// Kaç kez diske yazıldığı — testler bunu kontrol eder.
  int writes = 0;

  StoredSettings get current => _settings;

  @override
  Future<StoredSettings> load() async => _settings;

  @override
  Future<void> persist(StoredSettings settings) async {
    _settings = settings;
    writes++;
  }
}
