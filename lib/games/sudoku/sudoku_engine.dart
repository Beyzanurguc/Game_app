import 'dart:math';

/// Zorluk seviyeleri: açıkta bırakılan ipucu sayısı ve bitirme ödülleri.
enum SudokuDifficulty {
  kolay(
    'Kolay',
    'Bol ipucu, rahat başlangıç',
    clues: 45,
    completionBonus: 50,
    parSeconds: 300,
  ),
  orta(
    'Orta',
    'Biraz düşünmek gerek',
    clues: 36,
    completionBonus: 100,
    parSeconds: 480,
  ),
  zor(
    'Zor',
    'Gerçek bir meydan okuma',
    clues: 30,
    completionBonus: 150,
    parSeconds: 720,
  );

  const SudokuDifficulty(
    this.label,
    this.description, {
    required this.clues,
    required this.completionBonus,
    required this.parSeconds,
  });

  /// Ekranda gösterilen ad.
  final String label;

  /// Seçim sayfasındaki kısa açıklama.
  final String description;

  /// Başlangıçta dolu gelen hücre sayısı.
  final int clues;

  /// Bulmaca bitince eklenen puan.
  final int completionBonus;

  /// Hız bonusu için hedef süre.
  final int parSeconds;
}

/// 9x9 Sudoku bulmacası. Hücreler tek boyutlu listede tutulur (0 = boş).
class SudokuPuzzle {
  const SudokuPuzzle({
    required this.givens,
    required this.solution,
    required this.difficulty,
  });

  /// Başlangıç tahtası; 0 olan hücreler oyuncu tarafından doldurulur.
  final List<int> givens;

  /// Tek geçerli çözüm.
  final List<int> solution;

  final SudokuDifficulty difficulty;

  static const int size = 9;
  static const int cellCount = size * size;

  /// Rastgele, tek çözümü olan bir bulmaca üretir.
  factory SudokuPuzzle.generate(SudokuDifficulty difficulty, {Random? random}) {
    final rnd = random ?? Random();
    final solution = _generateSolution(rnd);
    final givens = _dig(solution, difficulty.clues, rnd);
    return SudokuPuzzle(
      givens: givens,
      solution: solution,
      difficulty: difficulty,
    );
  }

  bool isGiven(int index) => givens[index] != 0;

  static int rowOf(int index) => index ~/ size;

  static int colOf(int index) => index % size;

  static int boxOf(int index) => (rowOf(index) ~/ 3) * 3 + colOf(index) ~/ 3;

  /// İki hücre aynı satır, sütun veya 3x3 kutuda mı?
  static bool arePeers(int a, int b) =>
      a != b &&
      (rowOf(a) == rowOf(b) || colOf(a) == colOf(b) || boxOf(a) == boxOf(b));

  // --- Üretim ---------------------------------------------------------------

  static List<int> _generateSolution(Random rnd) {
    final grid = List<int>.filled(cellCount, 0);
    _fill(grid, 0, rnd);
    return grid;
  }

  static bool _fill(List<int> grid, int index, Random rnd) {
    if (index == cellCount) return true;
    final candidates = List<int>.generate(size, (i) => i + 1)..shuffle(rnd);
    for (final value in candidates) {
      if (!_isSafe(grid, index, value)) continue;
      grid[index] = value;
      if (_fill(grid, index + 1, rnd)) return true;
      grid[index] = 0;
    }
    return false;
  }

  /// Çözümden hücre siler; her silmede tek çözümlülük korunur.
  static List<int> _dig(List<int> solution, int clues, Random rnd) {
    final puzzle = List<int>.of(solution);
    final order = List<int>.generate(cellCount, (i) => i)..shuffle(rnd);
    var remaining = cellCount;

    for (final index in order) {
      if (remaining <= clues) break;
      final backup = puzzle[index];
      puzzle[index] = 0;
      if (_countSolutions(List<int>.of(puzzle), 2) == 1) {
        remaining--;
      } else {
        puzzle[index] = backup;
      }
    }
    return puzzle;
  }

  static bool _isSafe(List<int> grid, int index, int value) {
    final row = rowOf(index);
    final col = colOf(index);
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;

    for (var i = 0; i < size; i++) {
      if (grid[row * size + i] == value) return false;
      if (grid[i * size + col] == value) return false;
      final r = boxRow + i ~/ 3;
      final c = boxCol + i % 3;
      if (grid[r * size + c] == value) return false;
    }
    return true;
  }

  /// Geri izlemeli sayım; [limit] çözüme ulaşınca erken çıkar.
  static int _countSolutions(List<int> grid, int limit) {
    final index = grid.indexOf(0);
    if (index == -1) return 1;

    var found = 0;
    for (var value = 1; value <= size; value++) {
      if (!_isSafe(grid, index, value)) continue;
      grid[index] = value;
      found += _countSolutions(grid, limit - found);
      grid[index] = 0;
      if (found >= limit) break;
    }
    return found;
  }
}

/// Puanlama: her doğru sayı puan kazandırır, seri bozulmadıkça bonus büyür.
///
/// Çocuk kullanıcı için hatalar puan düşürmez; yalnızca seriyi sıfırlar.
class SudokuScore {
  /// Doğru hücrenin taban puanı.
  static const int correctBase = 10;

  /// Seri devam ettikçe eklenen puan.
  static const int streakStep = 2;

  /// Seri bonusunun üst sınırı.
  static const int maxStreakBonus = 10;

  /// İpucu kullanımının bedeli.
  static const int hintCost = 5;

  /// Bir bulmacada kullanılabilecek en fazla ipucu.
  static const int maxHints = 3;

  /// Bir bulmacada yapılabilecek en fazla hata; aşılırsa oyun biter.
  static const int maxMistakes = 3;

  /// Hatasız bitirme ödülü.
  static const int flawlessBonus = 50;

  /// Hedef sürenin altında bitirme ödülü.
  static const int speedBonus = 30;

  int points = 0;
  int streak = 0;
  int bestStreak = 0;
  int mistakes = 0;
  int hints = 0;
  bool finished = false;

  /// Doğru sayı girildi; kazanılan puanı döndürür.
  int registerCorrect() {
    streak++;
    if (streak > bestStreak) bestStreak = streak;
    final bonus = min((streak - 1) * streakStep, maxStreakBonus);
    final gain = correctBase + bonus;
    points += gain;
    return gain;
  }

  /// Yanlış sayı girildi; puan düşmez ama seri sıfırlanır.
  void registerMistake() {
    streak = 0;
    mistakes++;
  }

  /// İpucu alındı; küçük bir puan bedeli var.
  void registerHint() {
    hints++;
    streak = 0;
    points = max(0, points - hintCost);
  }

  /// Bulmaca tamamlandı; eklenen bonus puanı döndürür.
  int finish({required SudokuDifficulty difficulty, required Duration time}) {
    if (finished) return 0;
    finished = true;

    var bonus = difficulty.completionBonus;
    if (mistakes == 0) bonus += flawlessBonus;
    if (time.inSeconds <= difficulty.parSeconds) bonus += speedBonus;

    points += bonus;
    return bonus;
  }

  /// Kalan hata hakkı.
  int get mistakesLeft => (maxMistakes - mistakes).clamp(0, maxMistakes);

  /// Hata hakkı bitti mi?
  bool get failed => mistakes >= maxMistakes;

  /// Kalan ipucu hakkı.
  int get hintsLeft => (maxHints - hints).clamp(0, maxHints);

  bool get canUseHint => hints < maxHints;

  /// Ana sayfadaki yıldız sayacına eklenecek yıldız (1–5).
  int get starsEarned => (points ~/ 120).clamp(1, 5);
}
