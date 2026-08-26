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
import 'tetris_engine.dart';

/// Parça renkleri — Foxwood paletinden, her biri belirgin bir ton.
const _pieceColors = <Tetromino, Color>{
  Tetromino.i: AppColors.tertiaryContainer,
  Tetromino.o: AppColors.sunnyYellow,
  Tetromino.t: AppColors.plum,
  Tetromino.s: AppColors.leafGreen,
  Tetromino.z: AppColors.berryPink,
  Tetromino.j: AppColors.bandanaTeal,
  Tetromino.l: AppColors.foxOrange,
};

/// Tahta zemini: parçaların ve hayalet izin üzerinde belirgin durması için
/// ekran arka planından belirgin biçimde koyu.
const _boardColor = Color(0xFFE0CCBF);

/// Tetris oyun ekranı. Sudoku gibi alt gezinme çubuğu göstermez.
class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key, this.random, this.sequence});

  /// Testlerde tekrarlanabilir parça dizisi için.
  final Random? random;
  final List<Tetromino>? sequence;

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen> {
  late TetrisGame _game;
  Timer? _gravity;
  Timer? _clock;
  Duration _elapsed = Duration.zero;
  bool _paused = false;

  /// Kutlama yazısı için son görülen ilerleme.
  int _seenLines = 0;
  int _seenLevel = 1;
  String? _celebration;
  Timer? _celebrationTimer;

  final _keyboardFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _gravity?.cancel();
    _clock?.cancel();
    _celebrationTimer?.cancel();
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _startNewGame() {
    _gravity?.cancel();
    _clock?.cancel();

    setState(() {
      _game = TetrisGame(random: widget.random, sequence: widget.sequence);
      _elapsed = Duration.zero;
      _paused = false;
      _seenLines = 0;
      _seenLevel = 1;
      _celebration = null;
    });

    _scheduleGravity();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused || _game.over) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  /// Yerçekimi zamanlayıcısı her adımda yeniden kurulur; seviye artınca
  /// bir sonraki adım kendiliğinden hızlanır.
  void _scheduleGravity() {
    _gravity?.cancel();
    if (_game.over || _paused) return;

    _gravity = Timer(_game.gravity, () {
      if (!mounted) return;
      setState(_game.tick);
      _checkMilestones();
      if (_game.over) {
        _handleGameOver();
      } else {
        _scheduleGravity();
      }
    });
  }

  void _play(void Function() action) {
    if (_game.over || _paused) return;
    setState(action);
    _checkMilestones();
    if (_game.over) _handleGameOver();
  }

  /// Satır temizleme ve seviye atlama anlarında kutlama gösterir.
  void _checkMilestones() {
    if (_game.lines > _seenLines) {
      final cleared = _game.lines - _seenLines;
      _seenLines = _game.lines;
      _celebrate(cleared == 4 ? 'TETRİS!' : '$cleared SATIR!');
      HapticFeedback.mediumImpact();
    }
    if (_game.level > _seenLevel) {
      _seenLevel = _game.level;
      _celebrate('SEVİYE ${_game.level}!');
    }
  }

  void _celebrate(String text) {
    _celebrationTimer?.cancel();
    setState(() => _celebration = text);
    _celebrationTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _celebration = null);
    });
  }

  void _move(bool left) {
    _play(() => left ? _game.moveLeft() : _game.moveRight());
    HapticFeedback.selectionClick();
  }

  void _rotate() {
    _play(_game.rotate);
    HapticFeedback.selectionClick();
  }

  void _softDrop() {
    _play(_game.softDrop);
    _scheduleGravity();
  }

  void _hardDrop() {
    _play(_game.hardDrop);
    HapticFeedback.mediumImpact();
    _scheduleGravity();
  }

  Future<void> _togglePause() async {
    if (_game.over) return;

    setState(() => _paused = true);
    _gravity?.cancel();

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
        _scheduleGravity();
    }
  }

  Future<void> _handleGameOver() async {
    _gravity?.cancel();
    _clock?.cancel();
    HapticFeedback.heavyImpact();

    final summary = GameSummary(
      kind: GameKind.tetris,
      points: _game.score,
      stars: _game.starsEarned,
      elapsed: _elapsed,
      stats: [
        GameStat(
          icon: Icons.horizontal_rule_rounded,
          label: 'Satır',
          value: '${_game.lines}',
        ),
        GameStat(
          icon: Icons.trending_up_rounded,
          label: 'Seviye',
          value: '${_game.level}',
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

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _move(true);
      case LogicalKeyboardKey.arrowRight:
        _move(false);
      case LogicalKeyboardKey.arrowUp:
        _rotate();
      case LogicalKeyboardKey.arrowDown:
        _softDrop();
      case LogicalKeyboardKey.space:
        _hardDrop();
      case LogicalKeyboardKey.keyP:
        _togglePause();
      case LogicalKeyboardKey.keyX:
        // Hata ayıklama: ödül akışını görmek için oyunu bitirir.
        if (kDebugMode && !_game.over) {
          setState(_game.endGame);
          _handleGameOver();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: KeyboardListener(
        focusNode: _keyboardFocus,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Scaffold(
          // Tahtanın öne çıkması için zemin arka plandan bir ton koyu.
          backgroundColor: AppColors.surfaceContainerHigh,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
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
                            _Board(game: _game),
                            _Celebration(text: _celebration),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _Controls(
                        onLeft: () => _move(true),
                        onRight: () => _move(false),
                        onRotate: _rotate,
                        onDrop: _softDrop,
                        onHardDrop: _hardDrop,
                      ),
                    ],
                  ),
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
          keyValue: 'tetris_back',
        ),
        // Puan ve süre tek satırda: tahtaya daha çok dikey alan kalır.
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
                      key: ValueKey('tetris_score_$score'),
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
          keyValue: 'tetris_pause',
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
  });

  final IconData icon;
  final VoidCallback onTap;
  final String keyValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.game});

  final TetrisGame game;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NextPiecePreview(game: game),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatChip(
                icon: Icons.trending_up_rounded,
                label: 'Seviye ${game.level}',
                color: AppColors.foxOrange,
              ),
              _StatChip(
                icon: Icons.horizontal_rule_rounded,
                label: 'Satır ${game.lines}',
                color: AppColors.bandanaTeal,
              ),
            ],
          ),
        ),
        const Mascot(size: 46),
      ],
    );
  }
}

class _NextPiecePreview extends StatelessWidget {
  const _NextPiecePreview({required this.game});

  final TetrisGame game;

  @override
  Widget build(BuildContext context) {
    final size = game.nextPreviewSize;
    final cells = game.nextPreviewCells.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SIRADAKİ',
          style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        DepthBox(
          color: AppColors.creamBg,
          depthColor: AppColors.surfaceContainerHighest,
          borderColor: AppColors.outlineVariant,
          radius: AppRadius.sm,
          depth: 4,
          padding: const EdgeInsets.all(6),
          child: SizedBox(
            height: 44,
            width: 44,
            child: Column(
              children: [
                for (var row = 0; row < size; row++)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var col = 0; col < size; col++)
                          Expanded(
                            child: cells.contains((row: row, col: col))
                                ? Padding(
                                    padding: const EdgeInsets.all(1),
                                    child: _Block(type: game.next),
                                  )
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
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
  const _Board({required this.game});

  final TetrisGame game;

  @override
  Widget build(BuildContext context) {
    final falling = {for (final cell in game.currentCells) cell: game.current};
    final ghost = game.ghostCells.toSet();

    return Center(
      child: AspectRatio(
        aspectRatio: TetrisGame.cols / TetrisGame.rows,
        child: DepthBox(
          color: AppColors.creamBg,
          depthColor: AppColors.surfaceContainerHighest,
          borderColor: AppColors.earthBrown,
          radius: AppRadius.md,
          depth: 6,
          padding: const EdgeInsets.all(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: ColoredBox(
              color: _boardColor,
              child: Column(
                children: [
                  for (var row = 0; row < TetrisGame.rows; row++)
                    Expanded(
                      child: Row(
                        // Hücreler satırın tüm yüksekliğini kaplasın;
                        // aksi halde bloklar ve hayalet iz küçük kalır.
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var col = 0; col < TetrisGame.cols; col++)
                            Expanded(
                              child: _BoardCell(
                                // Hayalet hücreler testlerde anahtarla bulunur.
                                key: ghost.contains((row: row, col: col))
                                    ? ValueKey('ghost_${row}_$col')
                                    : null,
                                type:
                                    falling[(row: row, col: col)] ??
                                    game.cellAt(row, col),
                                ghostType: ghost.contains((row: row, col: col))
                                    ? game.current
                                    : null,
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
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({super.key, required this.type, required this.ghostType});

  final Tetromino? type;

  /// Doluysa bu hücre, parçanın ineceği yeri gösteren hayalet izdir.
  final Tetromino? ghostType;

  @override
  Widget build(BuildContext context) {
    if (type != null) {
      return Padding(
        padding: const EdgeInsets.all(0.5),
        child: _Block(type: type!),
      );
    }

    if (ghostType != null) {
      // Hayalet: parçanın kendi renginde belirgin bir çerçeve.
      // Hayalet iz: parçanın yarı saydam kopyası — nereye ineceği net görünür.
      final color = _pieceColors[ghostType]!;
      return Padding(
        padding: const EdgeInsets.all(0.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.9), width: 2),
          ),
        ),
      );
    }

    // Boş hücre: çizgi yok, düz zemin.
    return const SizedBox.shrink();
  }
}

/// Tek bir blok: yumuşak degrade, üstte ışık, altta gölge ve beyaz simge.
class _Block extends StatelessWidget {
  const _Block({required this.type});

  final Tetromino type;

  @override
  Widget build(BuildContext context) {
    final color = _pieceColors[type]!;
    final dark = _shade(color, -0.16);
    final light = _shade(color, 0.12);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
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
          child: CustomPaint(painter: _GlyphPainter(type)),
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

/// Her parça türüne özel küçük beyaz simge.
///
/// Renk körlüğünde de parçaları ayırt edilebilir kılar.
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.type);

  final Tetromino type;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    switch (type) {
      case Tetromino.i:
        canvas.drawCircle(center, r, paint);
      case Tetromino.o:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCircle(center: center, radius: r),
            const Radius.circular(1.5),
          ),
          paint,
        );
      case Tetromino.t:
        canvas.drawCircle(
          center,
          r * 0.8,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.shortestSide * 0.28,
        );
      case Tetromino.s:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - r)
            ..lineTo(center.dx - r, center.dy + r)
            ..lineTo(center.dx + r, center.dy + r)
            ..close(),
          paint,
        );
      case Tetromino.z:
        canvas.drawPath(
          Path()
            ..moveTo(center.dx, center.dy - r)
            ..lineTo(center.dx + r, center.dy)
            ..lineTo(center.dx, center.dy + r)
            ..lineTo(center.dx - r, center.dy)
            ..close(),
          paint,
        );
      case Tetromino.j:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: r * 2, height: r * 0.8),
          paint,
        );
      case Tetromino.l:
        canvas.drawRect(
          Rect.fromCenter(center: center, width: r * 2, height: r * 0.8),
          paint,
        );
        canvas.drawRect(
          Rect.fromCenter(center: center, width: r * 0.8, height: r * 2),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) => oldDelegate.type != type;
}

/// Satır temizleyince ya da seviye atlayınca beliren kutlama yazısı.
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

// ---------------------------------------------------------------------------
// Kontroller
// ---------------------------------------------------------------------------

class _Controls extends StatelessWidget {
  const _Controls({
    required this.onLeft,
    required this.onRight,
    required this.onRotate,
    required this.onDrop,
    required this.onHardDrop,
  });

  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onRotate;
  final VoidCallback onDrop;
  final VoidCallback onHardDrop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ControlButton(
                keyValue: 'tetris_left',
                icon: Icons.chevron_left_rounded,
                onPressed: onLeft,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ControlButton(
                keyValue: 'tetris_rotate',
                icon: Icons.rotate_right_rounded,
                color: AppColors.secondaryContainer,
                ink: AppColors.secondary,
                onPressed: onRotate,
                repeat: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ControlButton(
                keyValue: 'tetris_right',
                icon: Icons.chevron_right_rounded,
                onPressed: onRight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          key: const ValueKey('tetris_drop'),
          onLongPress: onHardDrop,
          child: _ControlButton(
            keyValue: 'tetris_drop_button',
            icon: Icons.keyboard_double_arrow_down_rounded,
            label: 'AŞAĞI',
            color: AppColors.foxOrange,
            ink: Colors.white,
            depth: AppColors.primary,
            onPressed: onDrop,
            // Basılı tutmak sert düşüş yapar; tekrar etmesin.
            repeat: false,
          ),
        ),
      ],
    );
  }
}

/// Basılı tutunca tekrar eden kontrol düğmesi.
class _ControlButton extends StatefulWidget {
  const _ControlButton({
    required this.keyValue,
    required this.icon,
    required this.onPressed,
    this.label,
    this.color = AppColors.creamBg,
    this.ink = AppColors.primary,
    this.depth,
    this.repeat = true,
  });

  final String keyValue;
  final IconData icon;
  final String? label;
  final Color color;
  final Color ink;
  final Color? depth;
  final VoidCallback onPressed;

  /// Basılı tutulunca hareketin tekrarlanıp tekrarlanmayacağı.
  final bool repeat;

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  Timer? _repeatTimer;

  void _startRepeat() {
    if (!widget.repeat) return;
    _repeatTimer?.cancel();
    _repeatTimer = Timer(const Duration(milliseconds: 300), () {
      _repeatTimer = Timer.periodic(
        const Duration(milliseconds: 90),
        (_) => widget.onPressed(),
      );
    });
  }

  void _stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _startRepeat(),
      onPointerUp: (_) => _stopRepeat(),
      onPointerCancel: (_) => _stopRepeat(),
      child: Squishy(
        key: ValueKey(widget.keyValue),
        onTap: widget.onPressed,
        color: widget.color,
        depthColor: widget.depth ?? AppColors.surfaceContainerHighest,
        borderColor: widget.depth == null ? AppColors.outlineVariant : null,
        radius: AppRadius.md,
        depth: 6,
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 26, color: widget.ink),
            if (widget.label != null) ...[
              const SizedBox(width: 6),
              Text(
                widget.label!,
                style: AppText.labelLg.copyWith(color: widget.ink),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
