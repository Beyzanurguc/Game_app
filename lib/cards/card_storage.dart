import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Diskten okunan/yazılan koleksiyon durumu.
typedef StoredCollection = ({Set<String> collected, int stars});

/// Koleksiyonun kalıcı kaydı. Test ve farklı platformlar için soyutlandı.
abstract interface class CardStorage {
  Future<StoredCollection> load();

  Future<void> persist(StoredCollection state);
}

/// `shared_preferences` tabanlı kalıcı kayıt.
///
/// Eklenti henüz kayıtlı değilse (ör. eklenti eklendikten sonra uygulama tam
/// yeniden derlenmeden çalıştırıldığında `MissingPluginException`) oyun
/// çökmez: kayıt o oturumda yalnızca bellekte kalır.
class SharedPreferencesCardStorage implements CardStorage {
  SharedPreferencesCardStorage();

  static const _collectedKey = 'collected_cards';
  static const _starsKey = 'stars';

  SharedPreferences? _prefs;

  /// Depolama kullanılabilir mi? Bir kez başarısız olursa tekrar denenmez.
  bool _available = true;

  Future<SharedPreferences?> get _instance async {
    if (!_available) return null;
    try {
      return _prefs ??= await SharedPreferences.getInstance();
    } catch (error) {
      _available = false;
      debugPrint(
        'Kalıcı kayıt kullanılamıyor ($error). '
        'Eklenti eklendikten sonra uygulamayı tamamen kapatıp '
        '"flutter run" ile yeniden derlemek gerekir.',
      );
      return null;
    }
  }

  @override
  Future<StoredCollection> load() async {
    final prefs = await _instance;
    if (prefs == null) return (collected: <String>{}, stars: 0);

    return (
      collected: (prefs.getStringList(_collectedKey) ?? const []).toSet(),
      stars: prefs.getInt(_starsKey) ?? 0,
    );
  }

  @override
  Future<void> persist(StoredCollection state) async {
    final prefs = await _instance;
    if (prefs == null) return;

    try {
      await prefs.setStringList(_collectedKey, state.collected.toList());
      await prefs.setInt(_starsKey, state.stars);
    } catch (error) {
      debugPrint('İlerleme kaydedilemedi: $error');
    }
  }
}

/// Testler için bellek içi kayıt.
class MemoryCardStorage implements CardStorage {
  MemoryCardStorage({Set<String>? collected, int stars = 0})
    : _collected = collected ?? <String>{},
      _stars = stars;

  Set<String> _collected;
  int _stars;

  /// Kaç kez diske yazıldığı — testler bunu kontrol eder.
  int writes = 0;

  @override
  Future<StoredCollection> load() async =>
      (collected: {..._collected}, stars: _stars);

  @override
  Future<void> persist(StoredCollection state) async {
    _collected = {...state.collected};
    _stars = state.stars;
    writes++;
  }
}
