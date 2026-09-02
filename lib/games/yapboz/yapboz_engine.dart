import 'dart:math';

/// Yapboz zorlukları. Zorluk yalnızca ızgara ölçüsünü değiştirir.
enum YapbozDifficulty {
  kolay('Kolay', 3, '9 parça'),
  orta('Orta', 4, '16 parça'),
  zor('Zor', 5, '25 parça');

  const YapbozDifficulty(this.label, this.size, this.pieceLabel);

  final String label;

  /// Izgaranın bir kenarındaki parça sayısı (size × size parça).
  final int size;

  /// Zorluk kartında gösterilen açıklama.
  final String pieceLabel;
}

/// Tek bir yapboz turunu yöneten motor.
///
/// Tahta `size × size` yuvadan oluşur. Her parçanın kalıcı bir [YapbozPiece.id]
/// değeri vardır ve bu id aynı zamanda parçanın **doğru yuva indeksidir**;
/// resmin sol üstten sağa doğru okunan sırası. Parçalar başlangıçta tepside
/// ([tray]) karışık durur, oyuncu sürükleyerek yuvalara yerleştirir.
///
/// Motor görselden habersizdir: hangi resmin kullanıldığı ekranın bileceği iş.
class YapbozEngine {
  YapbozEngine({required this.difficulty, Random? random})
    : _random = random ?? Random() {
    _slots = List<int?>.filled(slotCount, null);
    _tray = List<int>.generate(slotCount, (i) => i);
    _shuffleTray();
  }

  final YapbozDifficulty difficulty;
  final Random _random;

  /// Izgaranın bir kenarındaki parça sayısı.
  int get size => difficulty.size;

  /// Toplam parça (ve yuva) sayısı.
  int get slotCount => size * size;

  /// Yuvalardaki parça kimlikleri; boş yuva `null`.
  late List<int?> _slots;
  List<int?> get slots => List.unmodifiable(_slots);

  /// Tepside bekleyen parça kimlikleri, gösterim sırasıyla.
  late List<int> _tray;
  List<int> get tray => List.unmodifiable(_tray);

  /// Oyuncunun yaptığı yerleştirme sayısı (takaslar dâhil).
  int _moves = 0;
  int get moves => _moves;

  /// Yanlış yuvaya bırakılan parça sayısı — puanı düşürür.
  int _mistakes = 0;
  int get mistakes => _mistakes;

  /// Doğru yuvaya oturmuş parça sayısı.
  int get correctCount {
    var count = 0;
    for (var i = 0; i < slotCount; i++) {
      if (_slots[i] == i) count++;
    }
    return count;
  }

  /// 0–1 arası ilerleme; üstteki çubuk bu değeri kullanır.
  double get progress => slotCount == 0 ? 0 : correctCount / slotCount;

  /// Tüm parçalar doğru yuvada mı?
  bool get isSolved => correctCount == slotCount;

  /// [slotIndex] yuvasındaki parça doğru mu? Boşsa false.
  bool isSlotCorrect(int slotIndex) => _slots[slotIndex] == slotIndex;

  /// Parça nerede? Tepsideyse `null` döner.
  int? slotOf(int pieceId) {
    final index = _slots.indexOf(pieceId);
    return index == -1 ? null : index;
  }

  // ---------------------------------------------------------------------------
  // Hamleler
  // ---------------------------------------------------------------------------

  /// Bir parçayı yuvaya koyar.
  ///
  /// Parça tepsiden de gelebilir, başka bir yuvadan da. Hedef yuva doluysa
  /// oradaki parça, sürüklenen parçanın geldiği yere gider (yuvadan geldiyse
  /// takas, tepsiden geldiyse tepsiye döner).
  ///
  /// Doğru yuvaya oturan parça kilitlenmez; çocuk isterse yerinden alabilir.
  /// Dönen değer: parça doğru yuvasına mı kondu?
  bool place(int pieceId, int slotIndex) {
    assert(pieceId >= 0 && pieceId < slotCount, 'geçersiz parça: $pieceId');
    assert(
      slotIndex >= 0 && slotIndex < slotCount,
      'geçersiz yuva: $slotIndex',
    );

    final from = slotOf(pieceId);
    if (from == slotIndex) return isSlotCorrect(slotIndex);

    final displaced = _slots[slotIndex];

    if (from == null) {
      _tray.remove(pieceId);
    } else {
      _slots[from] = null;
    }

    _slots[slotIndex] = pieceId;

    if (displaced != null) {
      if (from == null) {
        // Tepsiden geldi: yerinden edilen parça tepsiye döner.
        _tray.add(displaced);
      } else {
        // Yuvadan geldi: iki parça yer değiştirir.
        _slots[from] = displaced;
      }
    }

    _moves++;
    final correct = slotIndex == pieceId;
    if (!correct) _mistakes++;
    return correct;
  }

  /// Yuvadaki parçayı tepsiye geri gönderir. Yuva boşsa hiçbir şey olmaz.
  void returnToTray(int slotIndex) {
    final pieceId = _slots[slotIndex];
    if (pieceId == null) return;

    _slots[slotIndex] = null;
    _tray.add(pieceId);
    _moves++;
  }

  /// Yanlış yerdeki bir parçayı doğru yuvasına taşır (ipucu).
  ///
  /// Yerleştirilecek parça kalmadıysa `null`, taşındıysa parçanın kimliği
  /// döner. İpucu hamle sayar ama hata sayılmaz.
  int? revealOne() {
    final candidates = [
      for (var i = 0; i < slotCount; i++)
        if (_slots[i] != i) i,
    ];
    if (candidates.isEmpty) return null;

    final target = candidates[_random.nextInt(candidates.length)];
    place(target, target);
    // İpucu doğru yerleştirme olduğu için hata eklemez; place() de eklemez.
    return target;
  }

  // ---------------------------------------------------------------------------
  // Puan
  // ---------------------------------------------------------------------------

  /// Parça başına taban puan — büyük yapboz daha çok kazandırır.
  int get _basePoints => slotCount * 10;

  /// Toplam puan.
  ///
  /// Taban puandan her hata için 5, geçen her 10 saniye için 2 puan düşer.
  /// Puan hiçbir zaman taban puanın beşte birinin altına inmez ki uzun süren
  /// bir tur bile ödülsüz kalmasın.
  int pointsFor(Duration elapsed) {
    if (!isSolved) return 0;
    final penalty = _mistakes * 5 + (elapsed.inSeconds ~/ 10) * 2;
    return max(_basePoints - penalty, _basePoints ~/ 5);
  }

  /// Yıldız: hatasız 3, az hatalı 2, bitirmek 1.
  ///
  /// Eşik parça sayısına göre ölçeklenir; 25 parçalık yapbozda birkaç hata
  /// 9 parçalıktakiyle aynı ağırlıkta olmamalı.
  int get stars {
    if (!isSolved) return 0;
    if (_mistakes == 0) return 3;
    if (_mistakes <= slotCount ~/ 3) return 2;
    return 1;
  }

  // ---------------------------------------------------------------------------
  // Kurulum
  // ---------------------------------------------------------------------------

  /// Tepsiyi karıştırır; hiçbir parça baştan doğru sırada kalmasın diye
  /// sıralı diziliş elenir.
  void _shuffleTray() {
    if (_tray.length < 2) return;
    for (var attempt = 0; attempt < 10; attempt++) {
      _tray.shuffle(_random);
      final sorted = [
        for (var i = 0; i < _tray.length; i++)
          if (_tray[i] == i) i,
      ];
      // Tepsi sırası ipucu vermesin: en fazla birkaç parça yerinde kalabilir.
      if (sorted.length <= _tray.length ~/ 4) return;
    }
  }
}
