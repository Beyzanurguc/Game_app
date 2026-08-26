import 'dart:math';

/// Tahtadaki bir hücrenin konumu.
typedef TetrisCell = ({int row, int col});

/// Yedi klasik tetromino.
enum Tetromino { i, o, t, s, z, j, l }

/// Parçaların temel biçimleri; diğer dönüşler bunlardan hesaplanır.
const _baseShapes = <Tetromino, List<String>>{
  Tetromino.i: ['....', 'XXXX', '....', '....'],
  Tetromino.o: ['XX', 'XX'],
  Tetromino.t: ['.X.', 'XXX', '...'],
  Tetromino.s: ['.XX', 'XX.', '...'],
  Tetromino.z: ['XX.', '.XX', '...'],
  Tetromino.j: ['X..', 'XXX', '...'],
  Tetromino.l: ['..X', 'XXX', '...'],
};

/// Her parça için 4 dönüş durumundaki dolu hücreler (kutu içi göreli konum).
final Map<Tetromino, List<List<TetrisCell>>> _rotations = {
  for (final entry in _baseShapes.entries)
    entry.key: _buildRotations(entry.value),
};

List<List<TetrisCell>> _buildRotations(List<String> base) {
  var grid = base.map((row) => row.split('')).toList();
  final states = <List<TetrisCell>>[];

  for (var i = 0; i < 4; i++) {
    states.add([
      for (var r = 0; r < grid.length; r++)
        for (var c = 0; c < grid.length; c++)
          if (grid[r][c] == 'X') (row: r, col: c),
    ]);
    grid = _rotateCw(grid);
  }
  return states;
}

List<List<String>> _rotateCw(List<List<String>> grid) {
  final n = grid.length;
  return List.generate(n, (r) => List.generate(n, (c) => grid[n - 1 - c][r]));
}

/// Tetris oyun durumu ve kuralları. Widget bağımlılığı yoktur.
class TetrisGame {
  TetrisGame({Random? random, List<Tetromino>? sequence})
    : _random = random ?? Random(),
      _sequence = sequence {
    _next = _nextPiece();
    _spawn();
  }

  static const int cols = 10;

  /// Telefon ekranında tahtanın genişliği doldurabilmesi için klasik 20 yerine
  /// 16 satır kullanılıyor; oyunlar da çocuklar için daha kısa sürüyor.
  static const int rows = 16;

  /// Tek satır temizlemenin taban puanı; çoklu temizlik daha çok kazandırır.
  static const List<int> lineScores = [0, 100, 300, 500, 800];

  /// Yumuşak düşüşte hücre başına puan.
  static const int softDropPoint = 1;

  /// Sert düşüşte hücre başına puan.
  static const int hardDropPoint = 2;

  /// Seviye atlamak için gereken satır sayısı.
  static const int linesPerLevel = 10;

  final Random _random;

  /// Verilirse parçalar bu sırayla gelir (testler ve senaryolar için).
  final List<Tetromino>? _sequence;
  int _sequenceIndex = 0;

  /// Yerleşmiş bloklar; boş hücreler null.
  final List<Tetromino?> board = List<Tetromino?>.filled(rows * cols, null);

  late Tetromino _current;
  late Tetromino _next;
  int _rotation = 0;
  int _row = 0;
  int _col = 0;

  int score = 0;
  int lines = 0;
  bool over = false;

  Tetromino get current => _current;

  Tetromino get next => _next;

  int get rotation => _rotation;

  /// Her 10 satırda bir artar.
  int get level => 1 + lines ~/ linesPerLevel;

  /// Seviye yükseldikçe parçalar hızlanır.
  Duration get gravity =>
      Duration(milliseconds: max(140, 800 - (level - 1) * 70));

  /// Ana sayfadaki sayaca eklenecek yıldız (1–5).
  int get starsEarned => (score ~/ 400).clamp(1, 5);

  Tetromino? cellAt(int row, int col) => board[row * cols + col];

  /// Düşmekte olan parçanın tahtadaki mutlak hücreleri.
  List<TetrisCell> get currentCells => _cellsAt(_rotation, _row, _col);

  /// Parçanın ineceği yeri gösteren hayalet konum.
  List<TetrisCell> get ghostCells {
    var row = _row;
    while (_fits(_rotation, row + 1, _col)) {
      row++;
    }
    return _cellsAt(_rotation, row, _col);
  }

  /// Sıradaki parçanın önizleme hücreleri (kutu içi göreli konum).
  List<TetrisCell> get nextPreviewCells => _rotations[_next]![0];

  /// Sıradaki parçanın önizleme kutusunun boyutu.
  int get nextPreviewSize => _baseShapes[_next]!.length;

  // --- Hareketler -----------------------------------------------------------

  bool moveLeft() => _tryMove(_row, _col - 1);

  bool moveRight() => _tryMove(_row, _col + 1);

  /// Saat yönünde döndürür; duvara denk gelirse bir-iki kare kaydırıp dener.
  bool rotate() {
    if (over) return false;
    final target = (_rotation + 1) % 4;

    for (final kick in const [0, -1, 1, -2, 2]) {
      if (_fits(target, _row, _col + kick)) {
        _rotation = target;
        _col += kick;
        return true;
      }
    }
    return false;
  }

  /// Yerçekimi adımı: bir satır iner, inemiyorsa parça yerleşir.
  void tick() {
    if (over) return;
    if (!_tryMove(_row + 1, _col)) _lock();
  }

  /// Oyuncunun bir satır aşağı itmesi; puan kazandırır.
  bool softDrop() {
    if (over) return false;
    if (_tryMove(_row + 1, _col)) {
      score += softDropPoint;
      return true;
    }
    _lock();
    return false;
  }

  /// Parçayı en dibe bırakır.
  int hardDrop() {
    if (over) return 0;

    var dropped = 0;
    while (_tryMove(_row + 1, _col)) {
      dropped++;
    }
    score += dropped * hardDropPoint;
    _lock();
    return dropped;
  }

  // --- İç işleyiş -----------------------------------------------------------

  List<TetrisCell> _cellsAt(int rotation, int row, int col) => [
    for (final cell in _rotations[_current]![rotation])
      (row: row + cell.row, col: col + cell.col),
  ];

  bool _tryMove(int row, int col) {
    if (over || !_fits(_rotation, row, col)) return false;
    _row = row;
    _col = col;
    return true;
  }

  /// Verilen konum tahtaya sığıyor mu (duvar, taban ve dolu hücre kontrolü)?
  bool _fits(int rotation, int row, int col) {
    for (final cell in _rotations[_current]![rotation]) {
      final r = row + cell.row;
      final c = col + cell.col;
      if (c < 0 || c >= cols || r >= rows) return false;
      if (r >= 0 && board[r * cols + c] != null) return false;
    }
    return true;
  }

  void _lock() {
    for (final cell in currentCells) {
      if (cell.row < 0) continue;
      board[cell.row * cols + cell.col] = _current;
    }
    final cleared = _clearLines();
    if (cleared > 0) {
      lines += cleared;
      score += lineScores[cleared] * level;
    }
    _spawn();
  }

  /// Dolan satırları siler ve üstündekileri indirir; silinen satır sayısını verir.
  int _clearLines() {
    var cleared = 0;

    for (var row = rows - 1; row >= 0; row--) {
      final full = List.generate(
        cols,
        (col) => board[row * cols + col],
      ).every((cell) => cell != null);
      if (!full) continue;

      cleared++;
      for (var r = row; r > 0; r--) {
        for (var c = 0; c < cols; c++) {
          board[r * cols + c] = board[(r - 1) * cols + c];
        }
      }
      for (var c = 0; c < cols; c++) {
        board[c] = null;
      }
      row++; // Aynı satırı yeniden kontrol et (üsttekiler indi).
    }
    return cleared;
  }

  void _spawn() {
    _current = _next;
    _next = _nextPiece();
    _rotation = 0;
    _row = 0;
    _col = (cols - _baseShapes[_current]!.length) ~/ 2;

    // Yeni parça sığmıyorsa tahta doldu demektir.
    if (!_fits(_rotation, _row, _col)) over = true;
  }

  Tetromino _nextPiece() {
    final sequence = _sequence;
    if (sequence != null && sequence.isNotEmpty) {
      return sequence[_sequenceIndex++ % sequence.length];
    }
    return Tetromino.values[_random.nextInt(Tetromino.values.length)];
  }

  /// Testler ve hata ayıklama için oyunu anında bitirir.
  void endGame() => over = true;
}
