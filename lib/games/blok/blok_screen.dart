import '../../settings/haptics.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../cards/card_collection.dart';
import '../../cards/reward_card_screen.dart';
import '../../profile/player_profile.dart';
import '../../settings/daily_limit_dialog.dart';
import '../../theme/app_theme.dart';
import '../../widgets/squishy.dart';
import '../game_dialogs.dart';
import '../game_summary.dart';
import 'blok_engine.dart';

/// Blok renkleri — Foxwood paletinden, her tür belirgin bir ton.
const _kindColors = <BlokKind, Color>{
  BlokKind.fox: AppColors.foxOrange,
  BlokKind.sun: AppColors.sunnyYellow,
  BlokKind.leaf: AppColors.leafGreen,
  BlokKind.teal: AppColors.bandanaTeal,
  BlokKind.sky: AppColors.tertiaryContainer,
  BlokKind.berry: AppColors.berryPink,
  BlokKind.plum: AppColors.plum,
};

/// Tahta zemini: blokların üzerinde belirgin durması için ekran arka planından
/// bir ton koyu (Tetris tahtasıyla aynı zemin).
const _boardColor = Color(0xFFE0CCBF);

/// Boş hücrenin rengi; ızgara görüntüsünü veren açık kareler.
const _emptyCellColor = Color(0xFFF6E7DC);

/// Sürüklenen parçanın parmağın ne kadar üstünde duracağı (hücre cinsinden).
const _dragLift = 1.15;

/// Bir turda kullanılabilecek ipucu sayısı.
const _hintLimit = 3;

/// Blok Patlat ekranı: 8x8 tahta, üç parçalık tepsi, satır/sütun temizleme.
///
/// Parçalar tepsiden tahtaya sürüklenerek konur; küçük parmaklar için
/// "parçaya dokun, sonra hücreye dokun" yolu da çalışır.
class BlokScreen extends StatefulWidget {
  const BlokScreen({super.key, this.random, this.sequence});

  /// Testlerde tekrarlanabilir parça dizisi için.
  final Random? random;
  final List<BlokPiece>? sequence;

  @override
  State<BlokScreen> createState() => _BlokScreenState();
}

class _BlokScreenState extends State<BlokScreen> {
  late BlokGame _game;
  Timer? _clock;
  Duration _elapsed = Duration.zero;
  bool _paused = false;

  /// Kutlama yazısı.
  String? _celebration;
  Timer? _celebrationTimer;

  /// Temizlenen hücrelerde kısa süre kalan parlama.
  Set<BlokCell> _flash = const {};
  Timer? _flashTimer;

  /// Dokunarak seçilen parça (sürüklemeye alternatif yol).
  int? _selected;

  /// Parmağın indiği parça ve nokta; eşik aşılınca sürükleme başlar.
  int? _pendingIndex;
  Offset? _pointerStart;

  /// Sürüklenen parça ve konumu.
  int? _dragIndex;
  Offset? _dragTopLeft;
  Offset _grab = Offset.zero;
  double _dragCell = 0;

  /// Sürüklerken tahtada gösterilen hedef.
  BlokMove? _preview;
  bool _previewValid = false;

  /// İpucu olarak yanıp sönen hamle.
  BlokMove? _hint;
  Timer? _hintTimer;
  int _hintsLeft = _hintLimit;

  final _stackKey = GlobalKey();
  final _boardKey = GlobalKey();
  final _pieceKeys = List.generate(BlokGame.trayCount, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _clock?.cancel();
    _celebrationTimer?.cancel();
    _flashTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _clock?.cancel();
    _celebrationTimer?.cancel();
    _flashTimer?.cancel();
    _hintTimer?.cancel();

    setState(() {
      _game = BlokGame(random: widget.random, sequence: widget.sequence);
      _elapsed = Duration.zero;
      _paused = false;
      _celebration = null;
      _flash = const {};
      _selected = null;
      _pendingIndex = null;
      _pointerStart = null;
      _dragIndex = null;
      _dragTopLeft = null;
      _preview = null;
      _hint = null;
      _hintsLeft = _hintLimit;
    });

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused || _game.over) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  // --- Yerleştirme ----------------------------------------------------------

  /// Tepsideki parçayı tahtaya koyar ve kutlama/ödül akışını tetikler.
  void _placePiece(int index, int row, int col) {
    final result = _game.place(index, row, col);
    if (result == null) {
      buzz(context, Buzz.selection);
      return;
    }

    setState(() {
      _selected = null;
      _hint = null;
    });

    if (result.clearedLines > 0) {
      buzz(context, Buzz.medium);
      _showFlash(result.clearedCells);
      _celebrate(_celebrationText(result));
    } else {
      buzz(context, Buzz.selection);
    }

    if (_game.over) _handleGameOver();
  }

  String _celebrationText(BlokPlacement result) {
    if (result.boardCleared) return 'TAHTA TEMİZ!';
    if (result.combo > 1) return 'KOMBO x${result.combo}!';
    if (result.clearedLines > 1) return '${result.clearedLines} SIRA!';
    return 'SÜPER!';
  }

  void _celebrate(String text) {
    _celebrationTimer?.cancel();
    setState(() => _celebration = text);
    _celebrationTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _celebration = null);
    });
  }

  void _showFlash(Set<BlokCell> cells) {
    _flashTimer?.cancel();
    setState(() => _flash = cells);
    _flashTimer = Timer(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _flash = const {});
    });
  }

  // --- Dokunarak yerleştirme ------------------------------------------------

  void _tapPiece(int index) {
    if (_game.over || _paused || _game.tray[index] == null) return;
    setState(() => _selected = _selected == index ? null : index);
    buzz(context, Buzz.selection);
  }

  /// Seçili parça, dokunulan hücre ortasına gelecek şekilde konur.
  void _tapCell(int row, int col) {
    final index = _selected;
    if (index == null) return;

    final piece = _game.tray[index];
    if (piece == null) return;

    final anchorRow = row - (piece.height - 1) ~/ 2;
    final anchorCol = col - (piece.width - 1) ~/ 2;
    _placePiece(index, anchorRow, anchorCol);
  }

  // --- Sürükleme ------------------------------------------------------------

  double? get _boardCellSize {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.size.width / BlokGame.size;
  }

  /// Parmak tepsideki parçaya indi; sürükleme henüz başlamadı.
  void _pointerDown(int index, Offset globalPosition) {
    _pendingIndex = index;
    _pointerStart = globalPosition;
  }

  /// Parmak yeterince kaydıysa sürükleme başlar, sonrası konum güncellemesi.
  ///
  /// Jest tanıyıcı yerine ham işaretçi olayları kullanılıyor: tek adımda
  /// yapılan hızlı sürüklemelerde de konum güncellemesi elimize geçiyor.
  void _pointerMove(Offset globalPosition) {
    if (_dragIndex == null) {
      final index = _pendingIndex;
      final start = _pointerStart;
      if (index == null || start == null) return;
      if ((globalPosition - start).distance < kTouchSlop) return;

      _startDrag(index, start);
      if (_dragIndex == null) return;
    }
    _updateDrag(globalPosition);
  }

  void _pointerUp(Offset globalPosition) {
    _pendingIndex = null;
    _pointerStart = null;
    if (_dragIndex == null) return;

    _updateDrag(globalPosition);
    _endDrag();
  }

  void _pointerCancel() {
    _pendingIndex = null;
    _pointerStart = null;
    if (_dragIndex != null) _cancelDrag();
  }

  /// Parmağın indiği noktadan sürüklemeyi başlatır.
  void _startDrag(int index, Offset globalPosition) {
    if (_game.over || _paused) return;

    final piece = _game.tray[index];
    final box =
        _pieceKeys[index].currentContext?.findRenderObject() as RenderBox?;
    final cell = _boardCellSize;
    if (piece == null || box == null || cell == null) return;

    // Parçanın neresinden tutulduğu hücre cinsinden saklanır; tepsideki
    // ölçek küçük olsa da tahtada aynı noktadan tutulmuş gibi davranır.
    final local = box.globalToLocal(globalPosition);
    final trayCell = box.size.width / piece.width;
    _grab = Offset(local.dx / trayCell, local.dy / trayCell);
    _dragCell = cell;

    setState(() {
      _dragIndex = index;
      _selected = null;
      _hint = null;
    });
  }

  void _updateDrag(Offset globalPosition) {
    final index = _dragIndex;
    if (index == null) return;

    final piece = _game.tray[index];
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (piece == null || boardBox == null || stackBox == null) return;

    final cell = boardBox.size.width / BlokGame.size;
    // Parça parmağın biraz üstünde durur; yoksa el parçayı kapatıyor.
    final topLeft =
        globalPosition -
        Offset(_grab.dx * cell, _grab.dy * cell) -
        Offset(0, cell * _dragLift);

    final onBoard = boardBox.globalToLocal(topLeft);
    final row = (onBoard.dy / cell).round();
    final col = (onBoard.dx / cell).round();
    final valid = _game.canPlaceAt(index, row, col);

    setState(() {
      _dragCell = cell;
      _dragTopLeft = stackBox.globalToLocal(topLeft);
      // Tahtadan tamamen uzaktayken hedef gösterilmez.
      _preview = _nearBoard(row, col, piece)
          ? (index: index, row: row, col: col)
          : null;
      _previewValid = valid;
    });
  }

  bool _nearBoard(int row, int col, BlokPiece piece) =>
      row > -piece.height &&
      row < BlokGame.size &&
      col > -piece.width &&
      col < BlokGame.size;

  void _endDrag() {
    final index = _dragIndex;
    final preview = _preview;
    final valid = _previewValid;

    setState(() {
      _dragIndex = null;
      _dragTopLeft = null;
      _preview = null;
    });

    if (index != null && preview != null && valid) {
      _placePiece(index, preview.row, preview.col);
    }
  }

  void _cancelDrag() {
    setState(() {
      _dragIndex = null;
      _dragTopLeft = null;
      _preview = null;
    });
  }

  // --- İpucu, duraklatma, oyun sonu ----------------------------------------

  void _useHint() {
    if (_game.over || _paused || _hintsLeft == 0) return;

    final move = _game.hint();
    if (move == null) return;

    _hintTimer?.cancel();
    setState(() {
      _hint = move;
      _hintsLeft--;
    });
    _hintTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  Future<void> _togglePause() async {
    if (_game.over) return;

    setState(() => _paused = true);
    final action = await showPauseDialog(context);
    if (!mounted) return;

    switch (action) {
      case PauseAction.restart:
        _startNewGame();
      case PauseAction.home:
        Navigator.of(context).pop();
      case PauseAction.resume:
      case null:
        setState(() => _paused = false);
    }
  }

  Future<void> _handleGameOver() async {
    _clock?.cancel();
    buzz(context, Buzz.heavy);

    final summary = GameSummary(
      kind: GameKind.blok,
      points: _game.score,
      stars: _game.starsEarned,
      elapsed: _elapsed,
      stats: [
        GameStat(
          icon: Icons.grid_view_rounded,
          label: 'Sıra',
          value: '${_game.lines}',
        ),
        GameStat(
          icon: Icons.bolt_rounded,
          label: 'Kombo',
          value: '${_game.bestCombo}',
        ),
      ],
    );
    // Tur istatistikleri rozet sayfasını besler.
    PlayerProfileScope.of(context).recordGame(summary);
    final draw = CardCollectionScope.of(context).drawReward();

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
      if (mounted) _startNewGame();
    } else if (mounted) {
      Navigator.of(context).pop(_game.starsEarned);
    }
  }

  Future<void> _handleBack() async {
    if (_game.over || _game.score == 0 || await confirmExitGame(context)) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  // --- Görünüm --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final dragPiece = _dragIndex == null ? null : _game.tray[_dragIndex!];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        // Tahtanın öne çıkması için zemin arka plandan bir ton koyu.
        backgroundColor: AppColors.surfaceContainerHigh,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  key: _stackKey,
                  children: [
                    Column(
                      children: [
                        _Header(
                          score: _game.score,
                          elapsed: _elapsed,
                          onBack: _handleBack,
                          onPause: _togglePause,
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(game: _game),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              _Board(
                                boardKey: _boardKey,
                                game: _game,
                                preview: _preview,
                                previewValid: _previewValid,
                                previewPiece: dragPiece,
                                hint: _hint,
                                hintPiece: _hint == null
                                    ? null
                                    : _game.tray[_hint!.index],
                                flash: _flash,
                                onCellTap: _tapCell,
                              ),
                              _Celebration(text: _celebration),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _Tray(
                          game: _game,
                          pieceKeys: _pieceKeys,
                          selected: _selected,
                          dragging: _dragIndex,
                          onTap: _tapPiece,
                          onPointerDown: _pointerDown,
                          onPointerMove: _pointerMove,
                          onPointerUp: _pointerUp,
                          onPointerCancel: _pointerCancel,
                        ),
                        const SizedBox(height: 10),
                        _HintBar(
                          hintsLeft: _hintsLeft,
                          onHint: _useHint,
                          onDebugEnd: kDebugMode && !_game.over
                              ? () {
                                  setState(_game.endGame);
                                  _handleGameOver();
                                }
                              : null,
                        ),
                      ],
                    ),
                    // Parmağı izleyen parça en üstte çizilir.
                    if (dragPiece != null && _dragTopLeft != null)
                      Positioned(
                        left: _dragTopLeft!.dx,
                        top: _dragTopLeft!.dy,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.92,
                            child: _PieceView(
                              piece: dragPiece,
                              cellSize: _dragCell,
                            ),
                          ),
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
}

// ---------------------------------------------------------------------------
// Üst bar ve bilgi satırı
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.score,
    required this.elapsed,
    required this.onBack,
    required this.onPause,
  });

  final int score;
  final Duration elapsed;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Row(
      children: [
        _RoundButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
          keyValue: 'blok_back',
          semanticLabel: 'Geri',
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.outlineVariant, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.sunnyYellow,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Text(
                      '$score',
                      key: ValueKey('blok_score_$score'),
                      style: AppText.headlineMd.copyWith(
                        color: AppColors.foxOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 18,
                    width: 1.5,
                    color: AppColors.outlineVariant,
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text('$minutes:$seconds', style: AppText.labelLg),
                ],
              ),
            ),
          ),
        ),
        _RoundButton(
          icon: Icons.pause_rounded,
          onTap: onPause,
          keyValue: 'blok_pause',
          semanticLabel: 'Duraklat',
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    required this.keyValue,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String keyValue;

  /// İçinde yazı yok; adı ekran okuyucuya buradan söylenir.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        key: ValueKey(keyValue),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.game});

  final BlokGame game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatChip(
                icon: Icons.grid_view_rounded,
                label: 'Sıra ${game.lines}',
                color: AppColors.bandanaTeal,
              ),
              _StatChip(
                icon: Icons.bolt_rounded,
                label: 'Kombo ${game.combo}',
                color: AppColors.foxOrange,
              ),
            ],
          ),
        ),
        const Mascot(size: 46),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
    required this.boardKey,
    required this.game,
    required this.preview,
    required this.previewValid,
    required this.previewPiece,
    required this.hint,
    required this.hintPiece,
    required this.flash,
    required this.onCellTap,
  });

  final Key boardKey;
  final BlokGame game;

  /// Sürüklenen parçanın hedefi.
  final BlokMove? preview;
  final bool previewValid;
  final BlokPiece? previewPiece;

  /// İpucunun gösterdiği hamle.
  final BlokMove? hint;
  final BlokPiece? hintPiece;

  /// Yeni temizlenmiş hücreler.
  final Set<BlokCell> flash;

  final void Function(int row, int col) onCellTap;

  /// Bir hamlenin tahtada kapladığı hücreler.
  static Set<BlokCell> _cellsOf(BlokMove? move, BlokPiece? piece) {
    if (move == null || piece == null) return const {};
    return {
      for (final cell in piece.cells)
        (row: move.row + cell.row, col: move.col + cell.col),
    };
  }

  @override
  Widget build(BuildContext context) {
    final previewCells = _cellsOf(preview, previewPiece);
    final hintCells = _cellsOf(hint, hintPiece);

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: DepthBox(
          color: AppColors.creamBg,
          depthColor: AppColors.surfaceContainerHighest,
          borderColor: AppColors.earthBrown,
          radius: AppRadius.md,
          depth: 6,
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: ColoredBox(
              color: _boardColor,
              child: SizedBox(
                key: boardKey,
                child: Column(
                  children: [
                    for (var row = 0; row < BlokGame.size; row++)
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var col = 0; col < BlokGame.size; col++)
                              Expanded(
                                child: GestureDetector(
                                  key: ValueKey('blok_cell_${row}_$col'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => onCellTap(row, col),
                                  child: _BoardCell(
                                    // Dolu hücreler testlerde anahtarla bulunur.
                                    key: game.cellAt(row, col) == null
                                        ? null
                                        : ValueKey('blok_filled_${row}_$col'),
                                    kind: game.cellAt(row, col),
                                    previewKind:
                                        previewCells.contains((
                                          row: row,
                                          col: col,
                                        ))
                                        ? previewPiece!.kind
                                        : null,
                                    previewValid: previewValid,
                                    hinted: hintCells.contains((
                                      row: row,
                                      col: col,
                                    )),
                                    flashing: flash.contains((
                                      row: row,
                                      col: col,
                                    )),
                                  ),
                                ),
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
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    super.key,
    required this.kind,
    required this.previewKind,
    required this.previewValid,
    required this.hinted,
    required this.flashing,
  });

  final BlokKind? kind;

  /// Doluysa sürüklenen parçanın bu hücreye denk gelen izi.
  final BlokKind? previewKind;
  final bool previewValid;

  /// İpucunun işaret ettiği hücre.
  final bool hinted;

  /// Az önce temizlenen hücre.
  final bool flashing;

  @override
  Widget build(BuildContext context) {
    if (kind != null) {
      return Padding(
        padding: const EdgeInsets.all(1),
        child: _Block(kind: kind!),
      );
    }

    if (previewKind != null) {
      // Geçerli hedef parçanın renginde, geçersiz hedef kırmızı çerçeveyle.
      final color = previewValid ? _kindColors[previewKind]! : AppColors.error;
      return Padding(
        padding: const EdgeInsets.all(1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: previewValid ? 0.45 : 0.2),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withValues(alpha: 0.9), width: 2),
          ),
        ),
      );
    }

    if (flashing) {
      return Padding(
        padding: const EdgeInsets.all(1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      );
    }

    if (hinted) {
      return Padding(
        padding: const EdgeInsets.all(1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.sunnyYellow.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.sunnyYellow, width: 2),
          ),
        ),
      );
    }

    // Boş hücre: ızgarayı görünür kılan açık kare.
    return Padding(
      padding: const EdgeInsets.all(1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _emptyCellColor,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tepsi
// ---------------------------------------------------------------------------

class _Tray extends StatelessWidget {
  const _Tray({
    required this.game,
    required this.pieceKeys,
    required this.selected,
    required this.dragging,
    required this.onTap,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  final BlokGame game;
  final List<GlobalKey> pieceKeys;
  final int? selected;
  final int? dragging;
  final void Function(int index) onTap;
  final void Function(int index, Offset globalPosition) onPointerDown;
  final void Function(Offset globalPosition) onPointerMove;
  final void Function(Offset globalPosition) onPointerUp;
  final VoidCallback onPointerCancel;

  /// Tepsideki bir yuvanın yüksekliği; 5'li çubuk da sığsın diye bol tutuldu.
  static const double _slotHeight = 96;

  @override
  Widget build(BuildContext context) {
    return DepthBox(
      color: AppColors.creamBg,
      depthColor: AppColors.surfaceContainerHighest,
      borderColor: AppColors.outlineVariant,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: SizedBox(
        height: _slotHeight,
        child: Row(
          children: [
            for (var i = 0; i < BlokGame.trayCount; i++)
              Expanded(
                child: _TraySlot(
                  index: i,
                  piece: game.tray[i],
                  pieceKey: pieceKeys[i],
                  selected: selected == i,
                  dragging: dragging == i,
                  onTap: () => onTap(i),
                  onPointerDown: (position) => onPointerDown(i, position),
                  onPointerMove: onPointerMove,
                  onPointerUp: onPointerUp,
                  onPointerCancel: onPointerCancel,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TraySlot extends StatelessWidget {
  const _TraySlot({
    required this.index,
    required this.piece,
    required this.pieceKey,
    required this.selected,
    required this.dragging,
    required this.onTap,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  final int index;
  final BlokPiece? piece;
  final GlobalKey pieceKey;
  final bool selected;
  final bool dragging;
  final VoidCallback onTap;
  final void Function(Offset globalPosition) onPointerDown;
  final void Function(Offset globalPosition) onPointerMove;
  final void Function(Offset globalPosition) onPointerUp;
  final VoidCallback onPointerCancel;

  /// Tepsideki hücre boyu üst sınırı; tahtadaki hücreden küçük durur.
  static const double _maxCell = 20;

  @override
  Widget build(BuildContext context) {
    final piece = this.piece;

    return LayoutBuilder(
      builder: (context, constraints) {
        final child = piece == null
            ? const _EmptySlot()
            : _PieceView(
                key: pieceKey,
                piece: piece,
                cellSize: min(
                  min(
                    (constraints.maxWidth - 16) / piece.width,
                    (constraints.maxHeight - 16) / piece.height,
                  ),
                  _maxCell,
                ),
                faded: dragging,
              );

        return Listener(
          key: ValueKey('blok_tray_$index'),
          onPointerDown: piece == null
              ? null
              : (event) => onPointerDown(event.position),
          onPointerMove: piece == null
              ? null
              : (event) => onPointerMove(event.position),
          onPointerUp: piece == null
              ? null
              : (event) => onPointerUp(event.position),
          onPointerCancel: piece == null ? null : (_) => onPointerCancel(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: piece == null ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.sunnyYellow.withValues(alpha: 0.28)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: selected ? AppColors.sunnyYellow : Colors.transparent,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      width: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 20,
          color: AppColors.outlineVariant,
        ),
      ),
    );
  }
}

/// Bir parçanın kutu görünümü; hem tepside hem sürüklerken kullanılır.
class _PieceView extends StatelessWidget {
  const _PieceView({
    super.key,
    required this.piece,
    required this.cellSize,
    this.faded = false,
  });

  final BlokPiece piece;
  final double cellSize;

  /// Sürüklenirken tepsideki kopya soluklaşır.
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final cells = piece.cells.toSet();
    final cell = max(cellSize, 4.0);

    return Opacity(
      opacity: faded ? 0.25 : 1,
      child: SizedBox(
        width: cell * piece.width,
        height: cell * piece.height,
        child: Column(
          children: [
            for (var row = 0; row < piece.height; row++)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var col = 0; col < piece.width; col++)
                      Expanded(
                        child: cells.contains((row: row, col: col))
                            ? Padding(
                                padding: const EdgeInsets.all(1),
                                child: _Block(kind: piece.kind),
                              )
                            : const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Tek bir blok: yumuşak degrade, üstte ışık, altta gölge ve beyaz simge.
class _Block extends StatelessWidget {
  const _Block({required this.kind});

  final BlokKind kind;

  @override
  Widget build(BuildContext context) {
    final color = _kindColors[kind]!;
    final dark = _shade(color, -0.16);
    final light = _shade(color, 0.12);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, color, dark],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.5),
            offset: const Offset(0, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.42,
          heightFactor: 0.42,
          child: CustomPaint(painter: _GlyphPainter(kind)),
        ),
      ),
    );
  }

  static Color _shade(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Her blok türüne özel küçük beyaz simge.
///
/// Renk körlüğünde de bloklar birbirinden ayırt edilebilir olur.
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.kind);

  final BlokKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    switch (kind) {
      case BlokKind.fox:
        canvas.drawCircle(center, r, paint);
      case BlokKind.sun:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: center, radius: r),
            const Radius.circular(1.5),
          ),
          paint,
        );
      case BlokKind.leaf:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - r)
            ..lineTo(center.dx - r, center.dy + r)
            ..lineTo(center.dx + r, center.dy + r)
            ..close(),
          paint,
        );
      case BlokKind.teal:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - r)
            ..lineTo(center.dx + r, center.dy)
            ..lineTo(center.dx, center.dy + r)
            ..lineTo(center.dx - r, center.dy)
            ..close(),
          paint,
        );
      case BlokKind.sky:
        canvas.drawCircle(
          center,
          r * 0.8,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.shortestSide * 0.28,
        );
      case BlokKind.berry:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: r * 2, height: r * 0.8),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(center: center, width: r * 0.8, height: r * 2),
          paint,
        );
      case BlokKind.plum:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: r * 2, height: r * 0.8),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) => oldDelegate.kind != kind;
}

// ---------------------------------------------------------------------------
// Kutlama ve ipucu
// ---------------------------------------------------------------------------

/// Sıra temizleyince beliren kutlama yazısı.
class _Celebration extends StatelessWidget {
  const _Celebration({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.7, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: text == null
            ? const SizedBox.shrink()
            : Container(
                key: ValueKey(text),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.foxOrange,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55F47D31),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  text!,
                  style: AppText.headlineMd.copyWith(color: Colors.white),
                ),
              ),
      ),
    );
  }
}

class _HintBar extends StatelessWidget {
  const _HintBar({
    required this.hintsLeft,
    required this.onHint,
    required this.onDebugEnd,
  });

  final int hintsLeft;
  final VoidCallback onHint;

  /// Hata ayıklama: ödül akışını görmek için oyunu bitirir.
  final VoidCallback? onDebugEnd;

  @override
  Widget build(BuildContext context) {
    final enabled = hintsLeft > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Squishy(
          key: const ValueKey('blok_hint'),
          onTap: enabled ? onHint : null,
          color: enabled ? AppColors.creamBg : AppColors.surfaceContainerLow,
          depthColor: AppColors.surfaceContainerHighest,
          borderColor: enabled
              ? AppColors.sunnyYellow
              : AppColors.outlineVariant,
          radius: AppRadius.md,
          depth: 5,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_rounded,
                size: 22,
                color: enabled ? AppColors.foxOrange : AppColors.outline,
              ),
              const SizedBox(width: 6),
              Text(
                'İPUCU $hintsLeft',
                style: AppText.labelLg.copyWith(
                  color: enabled ? AppColors.primary : AppColors.outline,
                ),
              ),
            ],
          ),
        ),
        if (onDebugEnd != null) ...[
          const SizedBox(width: 10),
          Squishy(
            key: const ValueKey('blok_debug_end'),
            onTap: onDebugEnd,
            color: AppColors.surfaceContainerLow,
            depthColor: AppColors.surfaceContainerHighest,
            borderColor: AppColors.outlineVariant,
            radius: AppRadius.md,
            depth: 5,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: const Icon(
              Icons.flag_rounded,
              size: 22,
              color: AppColors.outline,
            ),
          ),
        ],
      ],
    );
  }
}
