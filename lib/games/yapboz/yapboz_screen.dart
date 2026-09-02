import '../../settings/haptics.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../cards/card_collection.dart';
import '../../cards/reward_card_screen.dart';
import '../../profile/player_profile.dart';
import '../../settings/daily_limit_dialog.dart';
import '../../theme/app_theme.dart';
import '../../widgets/squishy.dart';
import '../game_dialogs.dart';
import '../game_summary.dart';
import 'puzzle_catalog.dart';
import 'puzzle_library.dart';
import 'yapboz_board.dart';
import 'yapboz_engine.dart';
import 'yapboz_setup.dart';

/// Yapboz ekranı.
///
/// İki aşamalıdır: önce resim ve zorluk seçilir ([YapbozSetupView]), sonra
/// tahta açılır. Oyun akışı diğer oyunlarla aynıdır:
///   YapbozScreen → GameSummary → RewardCardScreen → pop(stars)
class YapbozScreen extends StatefulWidget {
  const YapbozScreen({super.key});

  @override
  State<YapbozScreen> createState() => _YapbozScreenState();
}

class _YapbozScreenState extends State<YapbozScreen> {
  /// Seçim yapılmadan tahta kurulmaz.
  YapbozSetup? _setup;
  YapbozEngine? _engine;

  Duration _elapsed = Duration.zero;
  Timer? _clock;

  /// Kalan ipucu hakkı.
  int _hintsLeft = _hintLimit;
  static const _hintLimit = 3;

  /// Önizleme (tamamlanmış resim) açık mı?
  bool _showPreview = false;

  // --- Sürükleme durumu ------------------------------------------------------

  /// Sürüklenen parçanın kimliği.
  int? _dragPiece;

  /// Sürüklenen parça tahtadaki bir yuvadan mı geldi?
  int? _dragFromSlot;

  /// Parmağın altındaki hedef yuva.
  int? _hoverSlot;

  /// Parmağın son global konumu — parça bunun altında çizilir.
  Offset? _dragAt;

  final _boardKey = GlobalKey();

  /// Yüzen parçanın konumu bu yığına göre hesaplanır.
  final _stackKey = GlobalKey();

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Oyun akışı
  // ---------------------------------------------------------------------------

  void _start(YapbozSetup setup) {
    _clock?.cancel();
    setState(() {
      _setup = setup;
      _engine = YapbozEngine(difficulty: setup.difficulty);
      _elapsed = Duration.zero;
      _hintsLeft = _hintLimit;
      _showPreview = false;
      _dragPiece = null;
      _dragFromSlot = null;
      _hoverSlot = null;
      _dragAt = null;
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  /// Kurulum adımına döner (oyun içinden "başka resim").
  Future<void> _changePicture() async {
    if (!await confirmExitGame(context)) return;
    _clock?.cancel();
    if (!mounted) return;
    setState(() => _engine = null);
  }

  void _useHint() {
    final engine = _engine;
    if (engine == null || _hintsLeft <= 0 || engine.isSolved) return;

    final moved = engine.revealOne();
    if (moved == null) return;

    buzz(context, Buzz.light);
    setState(() => _hintsLeft--);
    _checkSolved();
  }

  void _checkSolved() {
    final engine = _engine;
    if (engine == null || !engine.isSolved) return;
    _clock?.cancel();
    // Son parçanın yerine oturduğu kare görünsün diye kısa bir bekleme.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _handleGameOver();
    });
  }

  Future<void> _handleGameOver() async {
    final engine = _engine;
    final setup = _setup;
    if (engine == null || setup == null) return;

    _clock?.cancel();
    buzz(context, Buzz.heavy);

    final summary = GameSummary(
      kind: GameKind.yapboz,
      points: engine.pointsFor(_elapsed),
      stars: engine.stars,
      elapsed: _elapsed,
      stats: [
        GameStat(
          icon: Icons.extension_rounded,
          label: 'Parça',
          value: '${engine.slotCount}',
        ),
        GameStat(
          icon: Icons.swap_horiz_rounded,
          label: 'Hamle',
          value: '${engine.moves}',
        ),
      ],
    );

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

    if (exit == RewardExit.replay && await ensurePlayAllowed(context)) {
      if (mounted) _start(setup);
    } else if (mounted) {
      Navigator.of(context).pop(engine.stars);
    }
  }

  Future<void> _handleBack() async {
    final engine = _engine;
    if (engine == null || engine.isSolved || await confirmExitGame(context)) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Sürükleme
  // ---------------------------------------------------------------------------

  /// Global bir noktanın hangi yuvaya denk geldiğini bulur; tahtanın dışıysa
  /// `null` döner.
  int? _slotAt(Offset globalPosition) {
    final engine = _engine;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (engine == null || box == null || !box.hasSize) return null;

    final local = box.globalToLocal(globalPosition);
    final cell = box.size.width / engine.size;
    if (local.dx < 0 || local.dy < 0) return null;

    final col = local.dx ~/ cell;
    final row = local.dy ~/ cell;
    if (row < 0 || row >= engine.size || col < 0 || col >= engine.size) {
      return null;
    }
    return row * engine.size + col;
  }

  void _dragStart(int pieceId, Offset globalPosition, {int? fromSlot}) {
    setState(() {
      _dragPiece = pieceId;
      _dragFromSlot = fromSlot;
      _hoverSlot = _slotAt(globalPosition);
      _dragAt = globalPosition;
    });
  }

  void _dragUpdate(Offset globalPosition) {
    if (_dragPiece == null) return;
    setState(() {
      _hoverSlot = _slotAt(globalPosition);
      _dragAt = globalPosition;
    });
  }

  void _dragEnd(Offset globalPosition) {
    final engine = _engine;
    final piece = _dragPiece;
    if (engine == null || piece == null) {
      setState(() {
        _dragPiece = null;
        _dragFromSlot = null;
        _hoverSlot = null;
        _dragAt = null;
      });
      return;
    }

    final slot = _slotAt(globalPosition);

    setState(() {
      if (slot != null) {
        final correct = engine.place(piece, slot);
        buzz(context, Buzz.selection);
        if (correct) buzz(context, Buzz.medium);
      } else if (_dragFromSlot != null) {
        // Tahtanın dışına bırakıldı: parça tepsiye döner.
        engine.returnToTray(_dragFromSlot!);
      }
      _dragPiece = null;
      _dragFromSlot = null;
      _hoverSlot = null;
      _dragAt = null;
    });

    _checkSolved();
  }

  void _dragCancel() {
    setState(() {
      _dragPiece = null;
      _dragFromSlot = null;
      _hoverSlot = null;
      _dragAt = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Görünüm
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    final setup = _setup;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: engine == null || setup == null
              ? _buildSetup(context)
              : Stack(
                  key: _stackKey,
                  children: [
                    _buildBoard(engine, setup),
                    ..._buildFloatingPiece(engine, setup),
                  ],
                ),
        ),
      ),
    );
  }

  /// Kurulum adımı. Yapboz listesi Firestore'dan gelir; boşsa oyun yerine
  /// ne olduğunu anlatan bir mesaj gösterilir.
  Widget _buildSetup(BuildContext context) {
    final pictures = PuzzleLibraryScope.of(context);
    if (pictures.isEmpty) {
      return _PuzzlesUnavailable(onBack: () => Navigator.of(context).pop());
    }

    return YapbozSetupView(
      pictures: pictures,
      initial: _setup,
      onStart: _start,
      onBack: () => Navigator.of(context).pop(),
    );
  }

  /// Parmağın altında sürüklenen parçayı çizer.
  ///
  /// Parça, Blok Patlat'taki gibi parmağın üstüne kaydırılmaz: yapbozda hangi
  /// yuvaya düşeceği tam olarak parmağın olduğu yerdir, kaydırma "buraya
  /// bıraktım ama şuraya gitti" hissi yaratıyor. Parça bir yuva kadar büyük
  /// olduğu için kenarları parmağın çevresinden zaten görünüyor.
  List<Widget> _buildFloatingPiece(YapbozEngine engine, YapbozSetup setup) {
    final pieceId = _dragPiece;
    final at = _dragAt;
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (pieceId == null ||
        at == null ||
        stackBox == null ||
        boardBox == null ||
        !boardBox.hasSize) {
      return const [];
    }

    // Parça, oturacağı yuvayla aynı boyda görünür.
    final cell = boardBox.size.width / engine.size;
    final local = stackBox.globalToLocal(at);

    return [
      Positioned(
        left: local.dx - cell / 2,
        top: local.dy - cell / 2,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.earthBrown.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: PuzzlePieceImage(
                picture: setup.picture,
                pieceId: pieceId,
                size: engine.size,
                extent: cell,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildBoard(YapbozEngine engine, YapbozSetup setup) {
    final accent = setup.picture.accent;

    return Column(
      children: [
        _YapbozAppBar(
          title: setup.picture.title,
          elapsed: _elapsed,
          onBack: _handleBack,
          onChangePicture: _changePicture,
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.base * 1.5,
              AppSpacing.marginMobile,
              AppSpacing.base * 2,
            ),
            children: [
              _ProgressSection(
                correct: engine.correctCount,
                total: engine.slotCount,
                progress: engine.progress,
                accent: accent,
              ),
              const SizedBox(height: AppSpacing.base * 1.5),

              // ── Tahta ──
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  key: _boardKey,
                  children: [
                    // Soluk önizleme: parçaların nereye geleceğini hatırlatır.
                    if (_showPreview)
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.35,
                          child: PuzzleImage(picture: setup.picture),
                        ),
                      ),
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cell = constraints.maxWidth / engine.size;
                          return Column(
                            children: [
                              for (var row = 0; row < engine.size; row++)
                                Row(
                                  children: [
                                    for (var col = 0; col < engine.size; col++)
                                      _buildSlot(
                                        engine,
                                        setup,
                                        row * engine.size + col,
                                        cell,
                                        accent,
                                      ),
                                  ],
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base * 2),

              // ── Yardım düğmeleri ──
              Row(
                children: [
                  Expanded(
                    child: _ToolButton(
                      key: const ValueKey('yapboz_preview'),
                      icon: _showPreview
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      label: _showPreview ? 'Resmi gizle' : 'Resmi göster',
                      onTap: () => setState(() => _showPreview = !_showPreview),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ToolButton(
                      key: const ValueKey('yapboz_hint'),
                      icon: Icons.lightbulb_rounded,
                      label: 'İpucu ($_hintsLeft)',
                      onTap: _hintsLeft > 0 && !engine.isSolved
                          ? _useHint
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base * 2),

              Text(
                'Parçalar',
                style: AppText.labelLg.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),

        // ── Parça tepsisi ──
        _PieceTray(
          engine: engine,
          picture: setup.picture,
          dragging: _dragPiece,
          onDragStart: _dragStart,
          onDragUpdate: _dragUpdate,
          onDragEnd: _dragEnd,
          onDragCancel: _dragCancel,
        ),
      ],
    );
  }

  Widget _buildSlot(
    YapbozEngine engine,
    YapbozSetup setup,
    int slotIndex,
    double cell,
    Color accent,
  ) {
    final pieceId = engine.slots[slotIndex];
    final isCorrect = engine.isSlotCorrect(slotIndex);
    // Sürüklenen parça hâlâ yuvada duruyormuş gibi görünmesin.
    final hidden = pieceId != null && pieceId == _dragPiece;

    return SizedBox(
      key: ValueKey('yapboz_slot_$slotIndex'),
      height: cell,
      width: cell,
      child: pieceId == null || hidden
          ? PuzzleSlotFrame(
              highlighted: _hoverSlot == slotIndex,
              accent: accent,
            )
          : _DraggablePiece(
              pieceId: pieceId,
              picture: setup.picture,
              size: engine.size,
              extent: cell,
              correct: isCorrect,
              accent: accent,
              highlighted: _hoverSlot == slotIndex,
              onStart: (position) =>
                  _dragStart(pieceId, position, fromSlot: slotIndex),
              onUpdate: _dragUpdate,
              onEnd: _dragEnd,
              onCancel: _dragCancel,
            ),
    );
  }
}

// =============================================================================
// Sürüklenebilir parça
// =============================================================================

/// Parçayı sürüklenebilir yapan sarmalayıcı.
///
/// [Draggable] yerine ham işaretçi olayları kullanılır: Blok Patlat'taki
/// yaklaşımın aynısı — hızlı sürüklemelerde de konum güncellemesi elimize
/// geçiyor ve parça parmağın biraz üstünde durabiliyor.
class _DraggablePiece extends StatelessWidget {
  const _DraggablePiece({
    required this.pieceId,
    required this.picture,
    required this.size,
    required this.extent,
    required this.correct,
    required this.accent,
    required this.highlighted,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final int pieceId;
  final PuzzlePicture picture;
  final int size;
  final double extent;

  /// Parça doğru yuvasında mı? Yeşil bir kenarla belli edilir.
  final bool correct;
  final Color accent;
  final bool highlighted;

  final void Function(Offset globalPosition) onStart;
  final void Function(Offset globalPosition) onUpdate;
  final void Function(Offset globalPosition) onEnd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) => onStart(event.position),
      onPointerMove: (event) => onUpdate(event.position),
      onPointerUp: (event) => onEnd(event.position),
      onPointerCancel: (_) => onCancel(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: highlighted
                ? accent
                : correct
                ? AppColors.leafGreen
                : AppColors.creamBg,
            width: correct || highlighted ? 2 : 1,
          ),
        ),
        child: PuzzlePieceImage(
          picture: picture,
          pieceId: pieceId,
          size: size,
          extent: extent,
        ),
      ),
    );
  }
}

// =============================================================================
// Parça tepsisi
// =============================================================================

class _PieceTray extends StatelessWidget {
  const _PieceTray({
    required this.engine,
    required this.picture,
    required this.dragging,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final YapbozEngine engine;
  final PuzzlePicture picture;
  final int? dragging;

  final void Function(int pieceId, Offset globalPosition) onDragStart;
  final void Function(Offset globalPosition) onDragUpdate;
  final void Function(Offset globalPosition) onDragEnd;
  final VoidCallback onDragCancel;

  /// Tepsideki parçaların kenar uzunluğu.
  static const _tileExtent = 64.0;

  @override
  Widget build(BuildContext context) {
    final tray = engine.tray;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _tileExtent + 28,
          child: tray.isEmpty
              ? Center(
                  child: Text(
                    engine.isSolved
                        ? 'Tamamlandı! 🎉'
                        : 'Tepsi boş — yanlış duran parçaları taşı.',
                    style: AppText.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  key: const ValueKey('yapboz_tray'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                    vertical: 14,
                  ),
                  itemCount: tray.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final pieceId = tray[index];
                    return Opacity(
                      // Sürüklenen parça tepside soluklaşır.
                      opacity: pieceId == dragging ? 0.3 : 1,
                      child: Listener(
                        onPointerDown: (event) =>
                            onDragStart(pieceId, event.position),
                        onPointerMove: (event) => onDragUpdate(event.position),
                        onPointerUp: (event) => onDragEnd(event.position),
                        onPointerCancel: (_) => onDragCancel(),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.outlineVariant,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: PuzzlePieceImage(
                              picture: picture,
                              pieceId: pieceId,
                              size: engine.size,
                              extent: _tileExtent,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

// =============================================================================
// App Bar
// =============================================================================

class _YapbozAppBar extends StatelessWidget {
  const _YapbozAppBar({
    required this.title,
    required this.elapsed,
    required this.onBack,
    required this.onChangePicture,
  });

  final String title;
  final Duration elapsed;
  final VoidCallback onBack;
  final VoidCallback onChangePicture;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          BackTapTarget(
            key: const ValueKey('yapboz_back'),
            onTap: onBack,
            color: AppColors.onSurfaceVariant,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppText.headlineMd.copyWith(color: AppColors.primary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.foxOrange, width: 2),
            ),
            child: Text(
              '$minutes:$seconds',
              style: AppText.labelLg.copyWith(color: AppColors.primary),
            ),
          ),
          GestureDetector(
            key: const ValueKey('yapboz_change_picture'),
            onTap: onChangePicture,
            child: Container(
              height: AppSpacing.touchTarget,
              width: AppSpacing.touchTarget,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// İlerleme
// =============================================================================

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.correct,
    required this.total,
    required this.progress,
    required this.accent,
  });

  final int correct;
  final int total;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Yerine oturan: $correct / $total',
              style: AppText.labelLg.copyWith(color: AppColors.secondary),
            ),
            Text(
              '%${(progress * 100).round()}',
              style: AppText.labelLg.copyWith(color: AppColors.secondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.sunnyYellow, accent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Yardım düğmesi
// =============================================================================

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Squishy(
      onTap: onTap,
      color: enabled ? AppColors.creamBg : AppColors.surfaceContainer,
      depthColor: enabled
          ? AppColors.surfaceContainerHighest
          : AppColors.surfaceContainerHigh,
      borderColor: enabled ? AppColors.outlineVariant : Colors.transparent,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.primary : AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppText.labelLg.copyWith(
                color: enabled ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Yapboz yoksa
// =============================================================================

class _PuzzlesUnavailable extends StatelessWidget {
  const _PuzzlesUnavailable({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Mascot(size: 120, mood: MascotMood.sad),
          const SizedBox(height: AppSpacing.base * 2),
          Text(
            'Yapbozlar yüklenemedi',
            textAlign: TextAlign.center,
            style: AppText.headlineMd.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            'Resimler internetten geliyor. Bağlantını kontrol edip '
            'uygulamayı yeniden açar mısın?',
            textAlign: TextAlign.center,
            style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.base * 3),
          Squishy(
            key: const ValueKey('yapboz_unavailable_back'),
            onTap: onBack,
            color: AppColors.foxOrange,
            depthColor: AppColors.primary,
            radius: AppRadius.md,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            child: Text(
              'GERİ DÖN',
              style: AppText.labelLg.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
