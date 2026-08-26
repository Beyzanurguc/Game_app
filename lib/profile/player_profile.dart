import 'package:flutter/widgets.dart';

import '../games/game_summary.dart';
import 'fox_items.dart';
import 'profile_storage.dart';

/// Oyuncunun oyun geçmişi ve tilki gardırobu.
///
/// Yıldız bakiyesi kart koleksiyonunda (cüzdan) durur; burada bugüne kadar
/// kazanılan **toplam** yıldız tutulur, böylece atölyede harcama yapmak
/// rozet ilerlemesini geri almaz.
///
/// [storage] verildiğinde her değişiklik diske yazılır; verilmezse yalnızca
/// bellekte tutulur (testler ve önizleme için).
class PlayerProfile extends ChangeNotifier {
  PlayerProfile({StoredProfile state = const StoredProfile(), this.storage})
    : _totalStarsEarned = state.totalStarsEarned,
      _records = {...state.records},
      _owned = {...state.owned},
      _equipped = {...state.equipped},
      _seenBadges = {...state.seenBadges};

  /// Kayıtlı durumu okuyup profili oluşturur.
  static Future<PlayerProfile> restore({
    required ProfileStorage storage,
  }) async {
    return PlayerProfile(state: await storage.load(), storage: storage);
  }

  final ProfileStorage? storage;

  int _totalStarsEarned;
  final Map<String, GameRecord> _records;
  final Set<String> _owned;
  final Map<String, String> _equipped;
  final Set<String> _seenBadges;

  /// Son yazma işlemi — testler `await profile.pending` diyebilir.
  Future<void> pending = Future.value();

  int get totalStarsEarned => _totalStarsEarned;

  /// Bütün oyunlarda toplam kaç tur oynandı.
  int get gamesPlayed =>
      _records.values.fold(0, (sum, record) => sum + record.plays);

  /// Herhangi bir oyundaki en yüksek tur puanı.
  int get bestScoreOverall => _records.values.fold(
    0,
    (best, record) => record.bestScore > best ? record.bestScore : best,
  );

  GameRecord recordOf(GameKind kind) =>
      _records[kind.name] ?? const GameRecord();

  /// Kaç farklı oyun en az [times] kez oynandı.
  int gamesPlayedAtLeast(int times) =>
      GameKind.values.where((kind) => recordOf(kind).plays >= times).length;

  Set<String> get ownedItems => Set.unmodifiable(_owned);

  int get ownedCount => _owned.length;

  bool owns(String id) => _owned.contains(id);

  /// Bölgedeki takılı aksesuar; boşsa null.
  FoxItem? equippedIn(FoxSlot slot) => foxItemById(_equipped[slot.name]);

  /// Takılı tüm aksesuarlar — avatar bunları çizer.
  List<FoxItem> get equippedItems => [
    for (final slot in FoxSlot.values) ?equippedIn(slot),
  ];

  bool isEquipped(FoxItem item) => _equipped[item.slot.name] == item.id;

  Set<String> get seenBadges => Set.unmodifiable(_seenBadges);

  bool hasSeenBadge(String id) => _seenBadges.contains(id);

  // --- Değişiklikler --------------------------------------------------------

  /// Biten bir oyun turunu istatistiklere işler.
  void recordGame(GameSummary summary) {
    _records[summary.kind.name] = recordOf(
      summary.kind,
    ).withResult(summary.points);
    _totalStarsEarned += summary.stars;
    _save();
  }

  /// Aksesuarı gardıroba ekler ve hemen takar. Zaten varsa false döner.
  ///
  /// Yıldız düşürme işlemi çağıran tarafta (cüzdanda) yapılır.
  bool unlock(FoxItem item) {
    if (!_owned.add(item.id)) return false;
    _equipped[item.slot.name] = item.id;
    _save();
    return true;
  }

  /// Sahip olunan aksesuarı takar; takılıysa çıkarır.
  void toggleEquip(FoxItem item) {
    if (!owns(item.id)) return;

    if (_equipped[item.slot.name] == item.id) {
      _equipped.remove(item.slot.name);
    } else {
      _equipped[item.slot.name] = item.id;
    }
    _save();
  }

  /// Bölgedeki aksesuarı çıkarır.
  void clearSlot(FoxSlot slot) {
    if (_equipped.remove(slot.name) == null) return;
    _save();
  }

  /// Rozetleri "görüldü" olarak işaretler; YENİ etiketi böyle kaybolur.
  void markBadgesSeen(Iterable<String> ids) {
    var added = false;
    for (final id in ids) {
      if (_seenBadges.add(id)) added = true;
    }
    if (added) _save();
  }

  /// Tüm ilerlemeyi sıfırlar (ayarlardaki "sıfırla" için).
  void reset() {
    _totalStarsEarned = 0;
    _records.clear();
    _owned.clear();
    _equipped.clear();
    _seenBadges.clear();
    _save();
  }

  StoredProfile snapshot() => StoredProfile(
    totalStarsEarned: _totalStarsEarned,
    records: {..._records},
    owned: {..._owned},
    equipped: {..._equipped},
    seenBadges: {..._seenBadges},
  );

  void _save() {
    final target = storage;
    if (target != null) pending = target.persist(snapshot());
    notifyListeners();
  }
}

/// Profili widget ağacına dağıtır ve değiştiğinde dinleyenleri yeniler.
class PlayerProfileScope extends InheritedNotifier<PlayerProfile> {
  const PlayerProfileScope({
    super.key,
    required PlayerProfile profile,
    required super.child,
  }) : super(notifier: profile);

  static PlayerProfile of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PlayerProfileScope>();
    assert(scope?.notifier != null, 'PlayerProfileScope bulunamadı');
    return scope!.notifier!;
  }
}
