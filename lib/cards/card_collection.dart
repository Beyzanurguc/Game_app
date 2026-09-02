import 'dart:math';

import 'package:flutter/widgets.dart';

import 'card_storage.dart';
import 'info_card.dart';

/// Oyun sonunda gösterilecek kart.
///
/// [isNew] false ise deste bitmiştir: kart albümde zaten vardır ve ödül ekranı
/// "yeni kartlar yakında" mesajıyla eski bir bilgiyi tekrar eder.
typedef RewardDraw = ({InfoCard card, bool isNew});

/// Oyuncunun kart koleksiyonu ve yıldızları.
///
/// [storage] verildiğinde her değişiklik diske yazılır; verilmezse yalnızca
/// bellekte tutulur (testler ve önizleme için).
class CardCollection extends ChangeNotifier {
  CardCollection({
    required this.deck,
    Iterable<String> collected = const [],
    this.stars = 0,
    Random? random,
    CardStorage? storage,
  }) : _collected = {...collected},
       _random = random ?? Random(),
       _storage = storage;

  /// Kayıtlı durumu okuyup koleksiyonu oluşturur.
  static Future<CardCollection> restore({
    required CardStorage storage,
    required List<InfoCard> deck,
    Random? random,
  }) async {
    final state = await storage.load();
    return CardCollection(
      deck: deck,
      collected: state.collected,
      stars: state.stars,
      random: random,
      storage: storage,
    );
  }

  final List<InfoCard> deck;
  final Set<String> _collected;
  final Random _random;
  final CardStorage? _storage;

  int stars;

  /// Son yazma işlemi — testler `await collection.pending` diyebilir.
  Future<void> pending = Future.value();

  int get total => deck.length;

  int get collectedCount => _collected.length;

  /// 0–1 arası ilerleme; albüm çubuğu bu değeri kullanır.
  double get progress => total == 0 ? 0 : collectedCount / total;

  bool isCollected(String id) => _collected.contains(id);

  /// Kategoriye göre kartlar; [category] boşsa tüm deste döner.
  List<InfoCard> byCategory(CardCategory? category) => category == null
      ? deck
      : deck.where((card) => card.category == category).toList();

  /// Albümde toplanacak kart kalmadı mı?
  bool get isComplete => collectedCount >= total;

  /// Oyun sonunda verilecek kartı seçer.
  ///
  /// Öncelik toplanmamış kartlarda. Hepsi toplanmışsa yeni kart yokmuş gibi
  /// davranılmaz: eski kartlardan biri `isNew: false` ile döner, ödül ekranı
  /// da bunu tekrar bilgisi olarak gösterir.
  RewardDraw drawReward() {
    final missing = deck.where((card) => !isCollected(card.id)).toList();
    if (missing.isNotEmpty) {
      return (card: missing[_random.nextInt(missing.length)], isNew: true);
    }
    return (card: deck[_random.nextInt(deck.length)], isNew: false);
  }

  /// Kartı albüme ekler. Zaten varsa false döner.
  bool save(InfoCard card) {
    final added = _collected.add(card.id);
    if (added) {
      _persist();
      notifyListeners();
    }
    return added;
  }

  void addStars(int amount) {
    if (amount <= 0) return;
    stars += amount;
    _persist();
    notifyListeners();
  }

  /// Yıldız harcar (tilki atölyesindeki alışveriş).
  ///
  /// Bakiye yetmiyorsa hiçbir şey değişmez ve false döner.
  bool spendStars(int amount) {
    if (amount <= 0 || amount > stars) return false;
    stars -= amount;
    _persist();
    notifyListeners();
    return true;
  }

  /// Tüm ilerlemeyi sıfırlar (ayarlardaki "sıfırla" için).
  void reset() {
    _collected.clear();
    stars = 0;
    _persist();
    notifyListeners();
  }

  void _persist() {
    final storage = _storage;
    if (storage == null) return;
    pending = storage.persist((collected: {..._collected}, stars: stars));
  }
}

/// Koleksiyonu widget ağacına dağıtır ve değiştiğinde dinleyenleri yeniler.
class CardCollectionScope extends InheritedNotifier<CardCollection> {
  const CardCollectionScope({
    super.key,
    required CardCollection collection,
    required super.child,
  }) : super(notifier: collection);

  static CardCollection of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CardCollectionScope>();
    assert(scope?.notifier != null, 'CardCollectionScope bulunamadı');
    return scope!.notifier!;
  }
}
