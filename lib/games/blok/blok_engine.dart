import 'dart:math';

/// Tahtadaki bir hücrenin konumu.
typedef BlokCell = ({int row, int col});

/// Bir parçanın tahtaya konacağı yer: tepsideki sıra ve sol üst köşe hücresi.
typedef BlokMove = ({int index, int row, int col});

/// Blok türleri. Her tür ayrı renk ve ayrı simge taşır; renk körlüğünde de
/// parçalar birbirinden ayırt edilebilir (Tetris ekranındaki yaklaşımın aynısı).
enum BlokKind { fox, sun, leaf, teal, sky, berry, plum }

/// Parça biçimleri ve çıkma ağırlıkları.
///
/// Büyük parçalar (5'li çubuk, 3x3 kare) daha düşük ağırlıkla gelir; aksi
/// halde 8x8 tahtada oyun çok erken tıkanıyor.
const _shapePatterns = <(List<String>, int)>[
  (['X'], 4),
  (['XX'], 6),
  (['X', 'X'], 6),
  (['XXX'], 6),
  (['X', 'X', 'X'], 6),
  (['XXXX'], 4),
  (['X', 'X', 'X', 'X'], 4),
  (['XXXXX'], 2),
  (['X', 'X', 'X', 'X', 'X'], 2),
  (['XX', 'XX'], 5),
  (['XXX', 'XXX', 'XXX'], 1),
  // 2x2 köşeler (dört dönüş).
  (['XX', 'X.'], 4),
  (['XX', '.X'], 4),
  (['X.', 'XX'], 4),
  (['.X', 'XX'], 4),
  // 2x3 L'ler.
  (['X..', 'XXX'], 3),
  (['..X', 'XXX'], 3),
  (['XXX', 'X..'], 3),
  (['XXX', '..X'], 3),
  // 3x2 L'ler.
  (['X.', 'X.', 'XX'], 3),
  (['.X', '.X', 'XX'], 3),
  (['XX', 'X.', 'X.'], 3),
  (['XX', '.X', '.X'], 3),
  // S / Z.
  (['XX.', '.XX'], 2),
  (['.XX', 'XX.'], 2),
  (['X.', 'XX', '.X'], 2),
  (['.X', 'XX', 'X.'], 2),
  // T.
  (['XXX', '.X.'], 2),
  (['.X.', 'XXX'], 2),
];

/// Desenden üretilmiş biçim: dolu hücreler ve kutu ölçüsü.
class _Shape {
  _Shape(List<String> rows, this.weight)
    : cells = [
        for (var r = 0; r < rows.length; r++)
          for (var c = 0; c < rows[r].length; c++)
            if (rows[r][c] == 'X') (row: r, col: c),
      ],
      height = rows.length,
      width = rows.first.length;

  final List<BlokCell> cells;
  final int width;
  final int height;
  final int weight;
}

final List<_Shape> _shapes = [
  for (final (rows, weight) in _shapePatterns) _Shape(rows, weight),
];

final int _totalWeight = _shapes.fold(0, (sum, shape) => sum + shape.weight);

/// Tepsideki tek bir parça.
class BlokPiece {
  const BlokPiece({
    required this.shapeIndex,
    required this.kind,
    required this.cells,
    required this.width,
    required this.height,
  });

  /// Verilen desenden parça üretir (testler ve senaryolar için).
  factory BlokPiece.fromPattern(
    List<String> rows, {
    BlokKind kind = BlokKind.fox,
  }) {
    final shape = _Shape(rows, 1);
    return BlokPiece(
      shapeIndex: -1,
      kind: kind,
      cells: shape.cells,
      width: shape.width,
      height: shape.height,
    );
  }

  /// Biçim listesindeki sıra; elle üretilen parçalarda -1.
  final int shapeIndex;
  final BlokKind kind;

  /// Dolu hücreler, parçanın kendi kutusuna göre.
  final List<BlokCell> cells;
  final int width;
  final int height;

  /// Parçanın kaç hücre kapladığı.
  int get size => cells.length;
}

/// Bir yerleştirmenin sonucu: temizlenen satır/sütunlar ve kazanılan puan.
class BlokPlacement {
  const BlokPlacement({
    required this.rows,
    required this.cols,
    required this.clearedCells,
    required this.gained,
    required this.combo,
    required this.boardCleared,
  });

  /// Temizlenen satır indeksleri.
  final List<int> rows;

  /// Temizlenen sütun indeksleri.
  final List<int> cols;

  /// Temizlenen tüm hücreler (parlama animasyonu için).
  final Set<BlokCell> clearedCells;

  /// Bu hamlede kazanılan puan.
  final int gained;

  /// Bu hamleden sonraki üst üste temizleme sayısı.
  final int combo;

  /// Tahta tamamen boşaldıysa true.
  final bool boardCleared;

  int get clearedLines => rows.length + cols.length;
}

/// Blok Patlat kuralları ve durumu. Widget bağımlılığı yoktur.
class BlokGame {
  BlokGame({Random? random, List<BlokPiece>? sequence})
    : _random = random ?? Random(),
      _sequence = sequence {
    _refillTray();
  }

  /// Tahta 8x8.
  static const int size = 8;

  /// Tepside aynı anda duran parça sayısı.
  static const int trayCount = 3;

  /// Yerleştirilen her hücrenin puanı.
  static const int pointPerCell = 1;

  /// Tek satır temizlemenin taban puanı; çoklu temizlik karesiyle büyür.
  static const int lineBase = 100;

  /// Üst üste temizlemelerde satır başına eklenen kombo puanı.
  static const int comboBonus = 50;

  /// Tahtayı tamamen boşaltmanın ödülü.
  static const int clearBoardBonus = 500;

  final Random _random;

  /// Verilirse parçalar bu sırayla gelir (testler için).
  final List<BlokPiece>? _sequence;
  int _sequenceIndex = 0;

  /// Yerleşmiş bloklar; boş hücreler null.
  final List<BlokKind?> board = List<BlokKind?>.filled(size * size, null);

  /// Tepsideki parçalar; kullanılan yuva null olur.
  final List<BlokPiece?> tray = List<BlokPiece?>.filled(trayCount, null);

  int score = 0;
  int lines = 0;
  int combo = 0;
  int bestCombo = 0;
  int placed = 0;
  bool over = false;

  BlokKind? cellAt(int row, int col) => board[row * size + col];

  /// Tepside kalan (henüz konmamış) parça sayısı.
  int get remainingPieces => tray.whereType<BlokPiece>().length;

  /// Ana sayfadaki sayaca eklenecek yıldız (1–5).
  int get starsEarned => (score ~/ 500).clamp(1, 5);

  /// Parça, sol üst köşesi (row, col) olacak şekilde tahtaya sığıyor mu?
  bool canPlace(BlokPiece piece, int row, int col) {
    for (final cell in piece.cells) {
      final r = row + cell.row;
      final c = col + cell.col;
      if (r < 0 || r >= size || c < 0 || c >= size) return false;
      if (board[r * size + c] != null) return false;
    }
    return true;
  }

  /// Tepsideki [index] parçası oraya konabilir mi?
  bool canPlaceAt(int index, int row, int col) {
    final piece = tray[index];
    if (over || piece == null) return false;
    return canPlace(piece, row, col);
  }

  /// Parçayı tahtaya koyar. Konamıyorsa null döner ve durum değişmez.
  BlokPlacement? place(int index, int row, int col) {
    if (!canPlaceAt(index, row, col)) return null;

    final piece = tray[index]!;
    for (final cell in piece.cells) {
      board[(row + cell.row) * size + col + cell.col] = piece.kind;
    }
    tray[index] = null;
    placed++;

    var gained = piece.size * pointPerCell;
    final result = _clearLines();

    if (result.clearedLines > 0) {
      combo++;
      if (combo > bestCombo) bestCombo = combo;
      lines += result.clearedLines;
      gained += lineBase * result.clearedLines * result.clearedLines;
      gained += comboBonus * (combo - 1) * result.clearedLines;
    } else {
      combo = 0;
    }

    final emptied = board.every((cell) => cell == null);
    if (emptied) gained += clearBoardBonus;

    score += gained;

    // Tepsi boşalınca yeni üç parça gelir.
    if (remainingPieces == 0) _refillTray();
    if (!hasAnyMove) over = true;

    return BlokPlacement(
      rows: result.rows,
      cols: result.cols,
      clearedCells: result.clearedCells,
      gained: gained,
      combo: combo,
      boardCleared: emptied,
    );
  }

  /// Tepsideki parçalardan biri için geçerli bir hamle var mı?
  bool get hasAnyMove => firstMove() != null;

  /// Oynanabilir ilk hamle; yoksa null.
  BlokMove? firstMove() {
    for (var index = 0; index < tray.length; index++) {
      final piece = tray[index];
      if (piece == null) continue;
      for (var row = 0; row <= size - piece.height; row++) {
        for (var col = 0; col <= size - piece.width; col++) {
          if (canPlace(piece, row, col)) {
            return (index: index, row: row, col: col);
          }
        }
      }
    }
    return null;
  }

  /// İpucu: varsa satır temizleyen bir hamle, yoksa herhangi bir geçerli hamle.
  BlokMove? hint() {
    BlokMove? fallback;

    for (var index = 0; index < tray.length; index++) {
      final piece = tray[index];
      if (piece == null) continue;
      for (var row = 0; row <= size - piece.height; row++) {
        for (var col = 0; col <= size - piece.width; col++) {
          if (!canPlace(piece, row, col)) continue;
          fallback ??= (index: index, row: row, col: col);
          if (_wouldClear(piece, row, col)) {
            return (index: index, row: row, col: col);
          }
        }
      }
    }
    return fallback;
  }

  /// Bu yerleştirme en az bir satır ya da sütun tamamlar mı?
  bool _wouldClear(BlokPiece piece, int row, int col) {
    final filled = {
      for (final cell in piece.cells)
        (row: row + cell.row, col: col + cell.col),
    };

    bool occupied(int r, int c) =>
        board[r * size + c] != null || filled.contains((row: r, col: c));

    for (final cell in filled) {
      if (List.generate(size, (c) => occupied(cell.row, c)).every((f) => f)) {
        return true;
      }
      if (List.generate(size, (r) => occupied(r, cell.col)).every((f) => f)) {
        return true;
      }
    }
    return false;
  }

  /// Dolan satır ve sütunları aynı anda hesaplayıp temizler.
  ({
    List<int> rows,
    List<int> cols,
    Set<BlokCell> clearedCells,
    int clearedLines,
  })
  _clearLines() {
    final fullRows = <int>[];
    final fullCols = <int>[];

    for (var row = 0; row < size; row++) {
      var full = true;
      for (var col = 0; col < size; col++) {
        if (board[row * size + col] == null) {
          full = false;
          break;
        }
      }
      if (full) fullRows.add(row);
    }
    for (var col = 0; col < size; col++) {
      var full = true;
      for (var row = 0; row < size; row++) {
        if (board[row * size + col] == null) {
          full = false;
          break;
        }
      }
      if (full) fullCols.add(col);
    }

    final cleared = <BlokCell>{};
    for (final row in fullRows) {
      for (var col = 0; col < size; col++) {
        cleared.add((row: row, col: col));
      }
    }
    for (final col in fullCols) {
      for (var row = 0; row < size; row++) {
        cleared.add((row: row, col: col));
      }
    }
    for (final cell in cleared) {
      board[cell.row * size + cell.col] = null;
    }

    return (
      rows: fullRows,
      cols: fullCols,
      clearedCells: cleared,
      clearedLines: fullRows.length + fullCols.length,
    );
  }

  void _refillTray() {
    for (var i = 0; i < tray.length; i++) {
      tray[i] = _nextPiece();
    }
  }

  BlokPiece _nextPiece() {
    final sequence = _sequence;
    if (sequence != null && sequence.isNotEmpty) {
      return sequence[_sequenceIndex++ % sequence.length];
    }

    var roll = _random.nextInt(_totalWeight);
    var shapeIndex = 0;
    for (var i = 0; i < _shapes.length; i++) {
      roll -= _shapes[i].weight;
      if (roll < 0) {
        shapeIndex = i;
        break;
      }
    }

    final shape = _shapes[shapeIndex];
    return BlokPiece(
      shapeIndex: shapeIndex,
      kind: BlokKind.values[_random.nextInt(BlokKind.values.length)],
      cells: shape.cells,
      width: shape.width,
      height: shape.height,
    );
  }

  /// Testler için: tek bir hücreyi doldurur ya da boşaltır.
  void debugSetCell(int row, int col, BlokKind? kind) {
    board[row * size + col] = kind;
  }

  /// Testler için: tepsiyi verilen parçalarla değiştirir.
  void debugSetTray(List<BlokPiece?> pieces) {
    for (var i = 0; i < tray.length; i++) {
      tray[i] = i < pieces.length ? pieces[i] : null;
    }
  }

  /// Testler ve hata ayıklama için oyunu anında bitirir.
  void endGame() => over = true;
}
