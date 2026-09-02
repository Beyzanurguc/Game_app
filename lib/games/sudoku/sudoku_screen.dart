import '../../settings/haptics.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../cards/card_collection.dart';
import '../../cards/reward_card_screen.dart';
import '../../profile/player_profile.dart';
import '../../settings/daily_limit_dialog.dart';
import '../../theme/app_theme.dart';
import '../../widgets/squishy.dart';
import '../game_dialogs.dart';
import '../game_summary.dart';
import 'sudoku_difficulty_sheet.dart';
import 'sudoku_engine.dart';

/// Sudoku oyun ekranı.
///
/// Oyun içinde alt gezinme çubuğu yoktur; çıkış yalnızca üstteki geri
/// düğmesiyle yapılır. Ekran kapanırken kazanılan yıldız sayısını döndürür.
class SudokuScreen extends StatefulWidget {
  const SudokuScreen({
    super.key,
    this.difficulty = SudokuDifficulty.kolay,
    this.random,
  });

  final SudokuDifficulty difficulty;

  /// Testlerde tekrarlanabilir bulmaca üretmek için kullanılır.
  final Random? random;

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  late SudokuDifficulty _difficulty = widget.difficulty;
  late SudokuPuzzle _puzzle;
  late List<int> _cells;

  /// Puan kazanılmış hücreler — silip yeniden yazarak puan toplanamasın.
  final _scored = <int>{};

  /// İpucuyla açılan hücreler.
  final _hinted = <int>{};

  /// Klavye kısayollarını yakalamak için (yalnızca hata ayıklama).
  final _keyboardFocus = FocusNode();

  /// Kalemle alınan küçük notlar (hücre başına aday sayılar).
  late List<Set<int>> _notes;

  /// Kalem açıkken sayılar değer değil, not olarak yazılır.
  bool _pencilMode = false;

  int? _selected;
  SudokuScore _score = SudokuScore();
  Duration _elapsed = Duration.zero;
  Timer? _ticker;

  /// Yanlış girişte maskot kısa süre üzgün görünür.
  bool _mascotSad = false;
  Timer? _sadTimer;

  @override
  void initState() {
    super.initState();
    _startNewGame(_difficulty);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _sadTimer?.cancel();
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _startNewGame(SudokuDifficulty difficulty) {
    _ticker?.cancel();
    _sadTimer?.cancel();

    setState(() {
      _difficulty = difficulty;
      _puzzle = SudokuPuzzle.generate(difficulty, random: widget.random);
      _cells = List<int>.of(_puzzle.givens);
      _notes = List<Set<int>>.generate(
        SudokuPuzzle.cellCount,
        (_) => <int>{},
        growable: false,
      );
      _pencilMode = false;
      _scored.clear();
      _hinted.clear();
      _selected = null;
      _score = SudokuScore();
      _elapsed = Duration.zero;
      _mascotSad = false;
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _score.finished) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  /// Tahta kilitli mi? (bulmaca bitti ya da hata hakkı doldu)
  bool get _locked => _score.finished || _score.failed;

  bool get _hasProgress =>
      _scored.isNotEmpty ||
      _hinted.isNotEmpty ||
      _cells.indexed.any((e) => e.$2 != _puzzle.givens[e.$1]);

  void _selectCell(int index) {
    if (_locked) return;
    setState(() => _selected = _selected == index ? null : index);
  }

  void _enterNumber(int value) {
    final index = _selected;
    if (index == null || _locked || _puzzle.isGiven(index)) return;

    // Kalem açıkken sayı, hücrenin köşesine not olarak yazılır/silinir.
    if (_pencilMode) {
      setState(() {
        _cells[index] = 0;
        _hinted.remove(index);
        if (!_notes[index].remove(value)) _notes[index].add(value);
      });
      buzz(context, Buzz.selection);
      return;
    }

    if (_cells[index] == value) return;

    final correct = value == _puzzle.solution[index];
    setState(() {
      // Yanlış değerin üzerine doğrudan yenisi yazılabilir.
      _cells[index] = value;
      _notes[index].clear();
      _hinted.remove(index);

      if (correct) {
        if (_scored.add(index)) _score.registerCorrect();
        _clearPeerNotes(index, value);
      } else {
        _score.registerMistake();
        _showSadMascot();
      }
    });

    if (correct) {
      buzz(context, Buzz.selection);
      _checkCompletion();
    } else {
      buzz(context, Buzz.medium);
      if (_score.failed) _handleGameOver();
    }
  }

  /// Seçili hücredeki değeri ve notları temizler.
  void _erase() {
    final index = _selected;
    if (index == null || _locked || _puzzle.isGiven(index)) return;
    if (_cells[index] == 0 && _notes[index].isEmpty) return;

    setState(() {
      _cells[index] = 0;
      _notes[index].clear();
      _hinted.remove(index);
    });
    buzz(context, Buzz.selection);
  }

  /// Bir sayı yerleşince aynı satır/sütun/kutudaki notlardan düşülür.
  void _clearPeerNotes(int index, int value) {
    for (var i = 0; i < SudokuPuzzle.cellCount; i++) {
      if (SudokuPuzzle.arePeers(index, i)) _notes[i].remove(value);
    }
  }

  void _useHint() {
    if (_locked) return;

    if (!_score.canUseHint) {
      _showMessage(
        'İpucu hakkın bitti! Bir bulmacada en fazla '
        '${SudokuScore.maxHints} ipucu alabilirsin.',
        AppColors.berryPink,
      );
      return;
    }

    // Önce seçili hücre, yoksa ilk boş/yanlış hücre açılır.
    var target = _selected;
    if (target == null || _cells[target] == _puzzle.solution[target]) {
      target = null;
      for (var i = 0; i < SudokuPuzzle.cellCount; i++) {
        if (_cells[i] != _puzzle.solution[i]) {
          target = i;
          break;
        }
      }
    }
    if (target == null) return;

    final index = target;
    setState(() {
      _cells[index] = _puzzle.solution[index];
      _notes[index].clear();
      _clearPeerNotes(index, _cells[index]);
      _hinted.add(index);
      _scored.add(index); // İpucuyla açılan hücre puan kazandırmaz.
      _selected = index;
      _score.registerHint();
    });
    _checkCompletion();
  }

  /// Yalnızca hata ayıklama derlemesinde çalışan test kısayolları.
  ///
  /// F: bulmacayı doğru sayılarla doldurur (ödül akışını görmek için)
  /// X: kasıtlı bir hata yapar (hata sınırını denemek için)
  void _handleDebugKey(KeyEvent event) {
    if (!kDebugMode || event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      _debugFillBoard();
    } else if (event.logicalKey == LogicalKeyboardKey.keyX) {
      _debugMakeMistake();
    }
  }

  void _debugFillBoard() {
    if (_locked) return;

    setState(() {
      for (var i = 0; i < SudokuPuzzle.cellCount; i++) {
        if (_cells[i] == _puzzle.solution[i]) continue;
        _cells[i] = _puzzle.solution[i];
        _notes[i].clear();
        if (_scored.add(i)) _score.registerCorrect();
      }
      _selected = null;
    });
    _checkCompletion();
  }

  void _debugMakeMistake() {
    if (_locked) return;

    final index = _cells.indexOf(0);
    if (index == -1) return;

    final correct = _puzzle.solution[index];
    setState(() {
      _cells[index] = correct == 9 ? 1 : correct + 1;
      _notes[index].clear();
      _score.registerMistake();
      _showSadMascot();
    });
    if (_score.failed) _handleGameOver();
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          content: Text(
            text,
            style: AppText.labelLg.copyWith(color: Colors.white),
          ),
        ),
      );
  }

  void _showSadMascot() {
    _sadTimer?.cancel();
    _mascotSad = true;
    _sadTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _mascotSad = false);
    });
  }

  void _checkCompletion() {
    for (var i = 0; i < SudokuPuzzle.cellCount; i++) {
      if (_cells[i] != _puzzle.solution[i]) return;
    }

    _ticker?.cancel();
    final bonus = _score.finish(difficulty: _difficulty, time: _elapsed);
    setState(() => _selected = null);
    buzz(context, Buzz.heavy);
    _showRewardCard(bonus);
  }

  /// Hata hakkı bitti: tahta kilitlenir, kart kazanılmaz.
  Future<void> _handleGameOver() async {
    _ticker?.cancel();
    buzz(context, Buzz.heavy);
    setState(() => _selected = null);

    final action = await showDialog<_GameOverAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GameOverDialog(score: _score, elapsed: _elapsed),
    );
    if (!mounted) return;

    if (action == _GameOverAction.retry && await ensurePlayAllowed(context)) {
      if (mounted) _startNewGame(_difficulty);
    } else if (mounted) {
      Navigator.of(context).pop(); // yıldız kazanılmadı
    }
  }

  /// Oyun bitince kazanılan bilgi kartını gösterir.
  Future<void> _showRewardCard(int bonus) async {
    final draw = CardCollectionScope.of(context).drawReward();
    final summary = GameSummary(
      kind: GameKind.sudoku,
      points: _score.points,
      stars: _score.starsEarned,
      elapsed: _elapsed,
      stats: [
        GameStat(
          icon: Icons.local_fire_department_rounded,
          label: 'En uzun seri',
          value: '${_score.bestStreak}',
        ),
        GameStat(
          icon: Icons.close_rounded,
          label: 'Hata',
          value: '${_score.mistakes}',
        ),
      ],
    );

    // Tur istatistikleri rozet sayfasını besler.
    PlayerProfileScope.of(context).recordGame(summary);

    final exit = await Navigator.of(context).push<RewardExit>(
      MaterialPageRoute(
        builder: (context) => RewardCardScreen(
          card: draw.card,
          isNew: draw.isNew,
          summary: summary,
        ),
      ),
    );
    if (!mounted) return;

    // Tekrar oynamak yeni bir tur: günlük haktan bir tane daha düşer.
    if (exit == RewardExit.replay && await ensurePlayAllowed(context)) {
      if (mounted) _startNewGame(_difficulty);
    } else if (mounted) {
      Navigator.of(context).pop(_score.starsEarned);
    }
  }

  Future<void> _pickDifficulty() async {
    final picked = await showSudokuDifficultySheet(
      context,
      current: _difficulty,
      subtitle: 'Yeni bulmaca başlar, bu oyun sıfırlanır.',
    );
    if (picked == null || !mounted) return;
    _startNewGame(picked);
  }

  Future<bool> _confirmExit() async {
    if (_score.finished || !_hasProgress) return true;
    return confirmExitGame(context);
  }

  Future<void> _handleBack() async {
    if (await _confirmExit() && mounted) {
      Navigator.of(context).pop(_score.finished ? _score.starsEarned : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      // Oyun ekranında alt gezinme çubuğu yok: dikkat tahtada kalsın.
      child: KeyboardListener(
        focusNode: _keyboardFocus,
        autofocus: true,
        onKeyEvent: _handleDebugKey,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    _Header(
                      points: _score.points,
                      elapsed: _elapsed,
                      onBack: _handleBack,
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.marginMobile,
                          4,
                          AppSpacing.marginMobile,
                          AppSpacing.gutter,
                        ),
                        children: [
                          _TitleRow(
                            difficulty: _difficulty,
                            mistakes: _score.mistakes,
                            streak: _score.streak,
                            mascotSad: _mascotSad,
                            onPickDifficulty: _pickDifficulty,
                          ),
                          const SizedBox(height: AppSpacing.base * 1.5),
                          _Board(
                            cells: _cells,
                            notes: _notes,
                            puzzle: _puzzle,
                            selected: _selected,
                            hinted: _hinted,
                            onTapCell: _selectCell,
                          ),
                          const SizedBox(height: AppSpacing.base * 2),
                          _ToolBar(
                            hintsLeft: _score.hintsLeft,
                            pencilActive: _pencilMode,
                            onPencil: () =>
                                setState(() => _pencilMode = !_pencilMode),
                            onErase: _erase,
                            onHint: _useHint,
                            onNewGame: () => _startNewGame(_difficulty),
                          ),
                          const SizedBox(height: AppSpacing.base * 1.5),
                          if (kDebugMode) const _DebugHint(),
                          _Numpad(
                            counts: _digitCounts(),
                            enabled: _selected != null && !_score.finished,
                            pencilMode: _pencilMode,
                            onNumber: _enterNumber,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Her rakamın tahtada kaç kez kullanıldığı (9 olunca tükenir).
  List<int> _digitCounts() {
    final counts = List<int>.filled(10, 0);
    for (final value in _cells) {
      if (value != 0) counts[value]++;
    }
    return counts;
  }
}

// ---------------------------------------------------------------------------
// Üst bar
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.points,
    required this.elapsed,
    required this.onBack,
  });

  final int points;
  final Duration elapsed;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        8,
        AppSpacing.marginMobile,
        8,
      ),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
            semanticLabel: 'Geri',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'PUAN',
                  style: AppText.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.sunnyYellow,
                      size: 26,
                    ),
                    const SizedBox(width: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Text(
                        '$points',
                        key: ValueKey(points),
                        style: AppText.headlineLg.copyWith(
                          color: AppColors.foxOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _TimeChip(elapsed: elapsed),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;

  /// İçinde yazı yok; adı ekran okuyucuya buradan söylenir.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppSpacing.touchTarget,
          width: AppSpacing.touchTarget,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.outlineVariant, width: 2),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.elapsed});

  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 5),
          Text('$minutes:$seconds', style: AppText.labelLg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Başlık satırı
// ---------------------------------------------------------------------------

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.difficulty,
    required this.mistakes,
    required this.streak,
    required this.mascotSad,
    required this.onPickDifficulty,
  });

  final SudokuDifficulty difficulty;
  final int mistakes;
  final int streak;
  final bool mascotSad;
  final VoidCallback onPickDifficulty;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sudoku',
                style: AppText.headlineLg.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  GestureDetector(
                    onTap: onPickDifficulty,
                    child: _Chip(
                      icon: Icons.tune_rounded,
                      label: difficulty.label,
                      color: AppColors.bandanaTeal,
                    ),
                  ),
                  _Chip(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Seri $streak',
                    color: AppColors.foxOrange,
                  ),
                  _Chip(
                    icon: Icons.favorite_rounded,
                    label: 'Hata $mistakes/${SudokuScore.maxMistakes}',
                    color: mistakes == 0 ? AppColors.outline : AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Mascot(
            key: ValueKey(mascotSad),
            size: 68,
            mood: mascotSad ? MascotMood.sad : MascotMood.happy,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(label, style: AppText.labelSm.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tahta
// ---------------------------------------------------------------------------

class _Board extends StatelessWidget {
  const _Board({
    required this.cells,
    required this.notes,
    required this.puzzle,
    required this.selected,
    required this.hinted,
    required this.onTapCell,
  });

  final List<int> cells;

  /// Hücre başına kalemle alınmış aday sayılar.
  final List<Set<int>> notes;
  final SudokuPuzzle puzzle;
  final int? selected;
  final Set<int> hinted;
  final ValueChanged<int> onTapCell;

  @override
  Widget build(BuildContext context) {
    return DepthBox(
      color: AppColors.creamBg,
      depthColor: AppColors.surfaceContainerHighest,
      borderColor: AppColors.earthBrown,
      radius: AppRadius.md,
      depth: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md - 2),
        child: AspectRatio(
          aspectRatio: 1,
          child: Column(
            children: [
              for (var row = 0; row < SudokuPuzzle.size; row++)
                Expanded(
                  child: Row(
                    children: [
                      for (var col = 0; col < SudokuPuzzle.size; col++)
                        Expanded(child: _buildCell(row * 9 + col)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    final value = cells[index];
    final given = puzzle.isGiven(index);
    final isSelected = selected == index;
    final wrong = value != 0 && value != puzzle.solution[index];
    final selectedValue = selected == null ? 0 : cells[selected!];

    final isPeer = selected != null && SudokuPuzzle.arePeers(selected!, index);
    final sameValue =
        selectedValue != 0 && value == selectedValue && !isSelected;

    final background = switch (true) {
      _ when wrong => AppColors.errorContainer,
      _ when isSelected => AppColors.sunnyYellow.withValues(alpha: 0.45),
      _ when sameValue => AppColors.secondaryContainer.withValues(alpha: 0.6),
      _ when isPeer => AppColors.surfaceContainerLow,
      _ when given => AppColors.surfaceContainer.withValues(alpha: 0.6),
      _ => Colors.transparent,
    };

    final textColor = switch (true) {
      _ when wrong => AppColors.onErrorContainer,
      _ when given => AppColors.earthBrown,
      _ when hinted.contains(index) => AppColors.secondary,
      _ => AppColors.foxOrange,
    };

    final row = SudokuPuzzle.rowOf(index);
    final col = SudokuPuzzle.colOf(index);

    return GestureDetector(
      key: ValueKey('cell_$index'),
      onTap: () => onTapCell(index),
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(
            right: _edge(col, thick: col % 3 == 2),
            bottom: _edge(row, thick: row % 3 == 2),
          ),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm - 4),
            border: Border.all(
              color: isSelected ? AppColors.foxOrange : Colors.transparent,
              width: 2.5,
            ),
          ),
          alignment: Alignment.center,
          child: value == 0
              ? _NotesGrid(notes: notes[index])
              : Text(
                  '$value',
                  style: AppText.headlineMd.copyWith(
                    color: textColor,
                    fontWeight: given ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  /// Son satır/sütunda kenarlık çizilmez; 3x3 sınırları daha kalındır.
  BorderSide _edge(int position, {required bool thick}) {
    if (position == SudokuPuzzle.size - 1) return BorderSide.none;
    return thick
        ? const BorderSide(color: AppColors.earthBrown, width: 2)
        : const BorderSide(color: AppColors.outlineVariant, width: 1);
  }
}

// ---------------------------------------------------------------------------
// Aksiyonlar ve tuş takımı
// ---------------------------------------------------------------------------

/// Boş hücrede kalemle alınan notların 3x3 dizilimi.
class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes});

  final Set<int> notes;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++)
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < 3; col++)
                    Expanded(
                      child: FittedBox(
                        child: Text(
                          notes.contains(row * 3 + col + 1)
                              ? '${row * 3 + col + 1}'
                              : ' ',
                          style: AppText.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Araçlar ve tuş takımı
// ---------------------------------------------------------------------------

/// Kalem, silgi, ipucu ve yeni oyun araçları.
class _ToolBar extends StatelessWidget {
  const _ToolBar({
    required this.hintsLeft,
    required this.pencilActive,
    required this.onPencil,
    required this.onErase,
    required this.onHint,
    required this.onNewGame,
  });

  /// Kalan ipucu hakkı; 0 olunca buton soluk görünür.
  final int hintsLeft;
  final bool pencilActive;
  final VoidCallback onPencil;
  final VoidCallback onErase;
  final VoidCallback onHint;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToolButton(
            key: const ValueKey('tool_pencil'),
            icon: Icons.edit_rounded,
            label: 'Kalem',
            color: AppColors.bandanaTeal,
            active: pencilActive,
            onTap: onPencil,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            key: const ValueKey('tool_eraser'),
            icon: Icons.backspace_rounded,
            label: 'Silgi',
            color: AppColors.berryPink,
            onTap: onErase,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            key: const ValueKey('tool_hint'),
            icon: Icons.lightbulb_rounded,
            label: 'İpucu $hintsLeft',
            color: AppColors.sunnyYellow,
            spent: hintsLeft == 0,
            onTap: onHint,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolButton(
            key: const ValueKey('tool_new'),
            icon: Icons.refresh_rounded,
            label: 'Yeni',
            color: AppColors.outline,
            onTap: onNewGame,
          ),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.active = false,
    this.spent = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  /// Açık/kapalı durumu olan araçlar (kalem) için.
  final bool active;

  /// Hakkı tükenmiş araç: soluk görünür ama dokunulunca uyarı verir.
  final bool spent;

  @override
  Widget build(BuildContext context) {
    final ink = active
        ? Colors.white
        : spent
        ? AppColors.outlineVariant
        : AppColors.onSurfaceVariant;

    return Squishy(
      onTap: onTap,
      color: active
          ? color
          : spent
          ? AppColors.surfaceContainerHigh
          : AppColors.creamBg,
      depthColor: color.withValues(alpha: active ? 0.7 : 0.35),
      borderColor: active ? color : AppColors.outlineVariant,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: active
                ? Colors.white
                : spent
                ? AppColors.outlineVariant
                : color,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.labelSm.copyWith(color: ink),
          ),
        ],
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  const _Numpad({
    required this.counts,
    required this.enabled,
    required this.pencilMode,
    required this.onNumber,
  });

  /// Rakamların tahtadaki kullanım sayısı (indeks 1–9).
  final List<int> counts;
  final bool enabled;
  final bool pencilMode;
  final ValueChanged<int> onNumber;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            !enabled
                ? 'Önce bir kutucuk seç, sonra sayıyı yaz.'
                : pencilMode
                ? 'Kalem açık: sayılar küçük not olarak yazılır.'
                : 'Sayıyı seç; yanlışsa üzerine yenisini yazabilirsin.',
            style: AppText.bodyMd.copyWith(
              color: pencilMode && enabled
                  ? AppColors.secondary
                  : AppColors.onSurfaceVariant,
              fontWeight: pencilMode && enabled
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
        ),
        _KeyRow(
          digits: const [1, 2, 3, 4, 5],
          counts: counts,
          enabled: enabled,
          pencilMode: pencilMode,
          onNumber: onNumber,
        ),
        const SizedBox(height: 8),
        _KeyRow(
          digits: const [6, 7, 8, 9],
          counts: counts,
          enabled: enabled,
          pencilMode: pencilMode,
          onNumber: onNumber,
          // Son satırda 5. sütun boş kalır; tuşlar hizada durur.
          trailingSpacer: true,
        ),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({
    required this.digits,
    required this.counts,
    required this.enabled,
    required this.pencilMode,
    required this.onNumber,
    this.trailingSpacer = false,
  });

  final List<int> digits;
  final List<int> counts;
  final bool enabled;
  final bool pencilMode;
  final ValueChanged<int> onNumber;
  final bool trailingSpacer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final digit in digits) ...[
          Expanded(
            child: _NumberKey(
              key: ValueKey('key_$digit'),
              digit: digit,
              // Kalem modunda tükenmiş sayılar da not olarak yazılabilir.
              exhausted: !pencilMode && counts[digit] >= 9,
              enabled: enabled,
              pencilMode: pencilMode,
              onTap: () => onNumber(digit),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (trailingSpacer) const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}

class _NumberKey extends StatelessWidget {
  const _NumberKey({
    super.key,
    required this.digit,
    required this.exhausted,
    required this.enabled,
    required this.pencilMode,
    required this.onTap,
  });

  final int digit;
  final bool exhausted;
  final bool enabled;
  final bool pencilMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = enabled && !exhausted;
    final ink = pencilMode ? AppColors.secondary : AppColors.primary;

    return Squishy(
      onTap: active ? onTap : null,
      color: active ? AppColors.creamBg : AppColors.surfaceContainerHigh,
      depthColor: active
          ? AppColors.surfaceContainerHighest
          : AppColors.surfaceContainerHigh,
      borderColor: active
          ? (pencilMode ? AppColors.secondaryContainer : AppColors.primaryFixed)
          : null,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          '$digit',
          style: AppText.headlineMd.copyWith(
            color: active ? ink : AppColors.outlineVariant,
          ),
        ),
      ),
    );
  }
}

/// Hata ayıklama derlemesinde görünen klavye kısayolu hatırlatıcısı.
class _DebugHint extends StatelessWidget {
  const _DebugHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.bug_report_rounded,
              size: 16,
              color: AppColors.outline,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Test: F = tahtayı doldur, X = hata yap',
                style: AppText.labelSm.copyWith(color: AppColors.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diyaloglar
// ---------------------------------------------------------------------------

enum _GameOverAction { retry, home }

/// Hata hakkı bitince gösterilen ekran.
class _GameOverDialog extends StatelessWidget {
  const _GameOverDialog({required this.score, required this.elapsed});

  final SudokuScore score;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.gutter),
      child: DepthBox(
        color: AppColors.creamBg,
        depthColor: AppColors.surfaceContainerHighest,
        borderColor: AppColors.berryPink,
        radius: AppRadius.lg,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(size: 110, mood: MascotMood.sad),
            const SizedBox(height: 10),
            Text(
              'Hata hakkın bitti',
              textAlign: TextAlign.center,
              style: AppText.headlineMd.copyWith(color: AppColors.berryPink),
            ),
            const SizedBox(height: 6),
            Text(
              '${SudokuScore.maxMistakes} hata yaptın, bu bulmaca burada '
              'bitti. Merak etme, yeni bir bulmaca seni bekliyor!',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MiniStat(label: 'Puan', value: '${score.points}'),
                const SizedBox(width: 10),
                _MiniStat(label: 'Süre', value: '$minutes:$seconds'),
                const SizedBox(width: 10),
                _MiniStat(label: 'En uzun seri', value: '${score.bestStreak}'),
              ],
            ),
            const SizedBox(height: 20),
            Squishy(
              key: const ValueKey('gameover_retry'),
              onTap: () => Navigator.of(context).pop(_GameOverAction.retry),
              color: AppColors.foxOrange,
              depthColor: AppColors.primary,
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: Text(
                  'TEKRAR DENE',
                  style: AppText.labelLg.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              key: const ValueKey('gameover_home'),
              onTap: () => Navigator.of(context).pop(_GameOverAction.home),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Ana sayfaya dön',
                  style: AppText.labelLg.copyWith(color: AppColors.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Text(value, style: AppText.labelLg),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
