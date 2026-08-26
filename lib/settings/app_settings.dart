import 'package:flutter/widgets.dart';

import 'settings_storage.dart';

/// Ad kutusunda kabul edilen karakterler: yalnızca harfler ve boşluk.
///
/// Hem yazarken süzmek (giriş sayfasındaki `inputFormatters`) hem de kaydetmeden
/// önce temizlemek ([sanitizeChildName]) için aynı desen kullanılır.
final RegExp childNameCharacters = RegExp(r'[A-Za-zÇĞİÖŞÜÂÎÛçğıöşüâîû ]');

/// Girilen adı kaydedilebilir hâle getirir.
///
/// Harf dışındaki her şeyi atar, araya sıkışan boşlukları teke indirir ve
/// [maxChildNameLength] sınırını uygular. Boş dönebilir: ad zorunlu değil.
String sanitizeChildName(String raw) {
  final letters = raw.split('').where(childNameCharacters.hasMatch).join();
  final collapsed = letters.replaceAll(RegExp(r' +'), ' ').trim();
  if (collapsed.length <= maxChildNameLength) return collapsed;
  return collapsed.substring(0, maxChildNameLength).trim();
}

/// Giriş sayfasında toplanan ayarlar ve günlük oyun hakkı sayacı.
///
/// [storage] verildiğinde her değişiklik diske yazılır; verilmezse yalnızca
/// bellekte tutulur (testler ve önizleme için).
class AppSettings extends ChangeNotifier {
  AppSettings({
    StoredSettings state = const StoredSettings(),
    this.storage,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _childName = state.childName,
       _dailyGameLimit = state.dailyGameLimit,
       _onboarded = state.onboarded,
       _playDate = state.playDate,
       _playsToday = state.playsToday;

  /// Kayıtlı durumu okuyup ayarları oluşturur.
  static Future<AppSettings> restore({required SettingsStorage storage}) async {
    return AppSettings(state: await storage.load(), storage: storage);
  }

  final SettingsStorage? storage;

  /// Gün dönümünü test edebilmek için saat dışarıdan verilebilir.
  final DateTime Function() _clock;

  String _childName;
  int _dailyGameLimit;
  bool _onboarded;
  String _playDate;
  int _playsToday;

  /// Son yazma işlemi — testler `await settings.pending` diyebilir.
  Future<void> pending = Future.value();

  /// Çocuğun adı; giriş sayfasında boş bırakılmış olabilir.
  String get childName => _childName;

  bool get hasName => _childName.isNotEmpty;

  int get dailyGameLimit => _dailyGameLimit;

  /// Giriş sayfası tamamlandı mı?
  bool get onboarded => _onboarded;

  /// Bugün başlanan tur sayısı. Gün değişmişse kendiliğinden sıfırdır.
  int get playsToday => _playDate == _dateKey(_clock()) ? _playsToday : 0;

  /// Bugün kalan oyun hakkı.
  int get remainingPlays =>
      (_dailyGameLimit - playsToday).clamp(0, _dailyGameLimit);

  /// Yeni bir tur başlatılabilir mi?
  bool get canPlay => remainingPlays > 0;

  /// Giriş sayfasındaki bilgileri kaydeder ve ana sayfaya geçişi açar.
  void completeOnboarding({String name = '', required int dailyGameLimit}) {
    _childName = sanitizeChildName(name);
    _dailyGameLimit = _clampLimit(dailyGameLimit);
    _onboarded = true;
    _save();
  }

  /// Ayarlar sayfasından adı değiştirir.
  ///
  /// Giriş sayfasındaki ile aynı temizlikten geçer; boşaltılabilir.
  void updateChildName(String name) {
    final cleaned = sanitizeChildName(name);
    if (cleaned == _childName) return;
    _childName = cleaned;
    _save();
  }

  /// Ayarlar sayfasından günlük limiti değiştirir.
  ///
  /// Bugünkü sayaca dokunulmaz: limit düşürülürse kalan hak hemen azalır,
  /// yükseltilirse aradaki fark bugün de kullanılabilir.
  void updateDailyGameLimit(int limit) {
    final clamped = _clampLimit(limit);
    if (clamped == _dailyGameLimit) return;
    _dailyGameLimit = clamped;
    _save();
  }

  /// Yeni bir tur başladı; günlük haktan bir tane düşer.
  void recordPlay() {
    final today = _dateKey(_clock());
    if (_playDate != today) {
      _playDate = today;
      _playsToday = 0;
    }
    _playsToday++;
    _save();
  }

  StoredSettings snapshot() => StoredSettings(
    childName: _childName,
    dailyGameLimit: _dailyGameLimit,
    onboarded: _onboarded,
    playDate: _playDate,
    playsToday: _playsToday,
  );

  void _save() {
    final target = storage;
    if (target != null) pending = target.persist(snapshot());
    notifyListeners();
  }
}

int _clampLimit(int limit) => limit.clamp(minDailyGameLimit, maxDailyGameLimit);

String _dateKey(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}-'
    '${time.month.toString().padLeft(2, '0')}-'
    '${time.day.toString().padLeft(2, '0')}';

/// Ayarları widget ağacına dağıtır ve değiştiğinde dinleyenleri yeniler.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope?.notifier != null, 'AppSettingsScope bulunamadı');
    return scope!.notifier!;
  }
}
