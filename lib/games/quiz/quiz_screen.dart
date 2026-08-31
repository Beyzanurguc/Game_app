import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../cards/card_collection.dart';
import '../../cards/info_card.dart';
import '../../cards/reward_card_screen.dart';
import '../../profile/player_profile.dart';
import '../../settings/daily_limit_dialog.dart';
import '../../theme/app_theme.dart';
import '../../widgets/squishy.dart';
import '../game_dialogs.dart';
import '../game_summary.dart';
import 'quiz_engine.dart';

/// Bilgi Yarışması ekranı.
///
/// [card_deck.dart] içindeki bilgi kartlarından çoktan seçmeli sorular üretir.
/// Oyun akışı diğer oyunlarla aynıdır:
///   QuizScreen → GameSummary → RewardCardScreen → pop(stars)
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late QuizEngine _engine;

  /// Motor koleksiyona ihtiyaç duyduğu için [didChangeDependencies] içinde
  /// kurulur; bu bayrak bir kez kurulmasını sağlar.
  bool _engineReady = false;

  Timer? _questionTimer;
  int _remainingSeconds = QuizEngine.timePerQuestion;
  Duration _totalElapsed = Duration.zero;
  Timer? _clock;

  /// Kullanıcının bu soruda seçtiği şık (-1 = henüz seçmedi).
  int _selected = -1;

  /// Cevap verildi mi (doğru/yanlış gösteriliyor)?
  bool _answered = false;

  /// Doğru mu?
  bool _wasCorrect = false;

  /// Soru geçiş animasyonu.
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_engineReady) return;
    _engineReady = true;

    _engine = _buildEngine();
    _startClock();
    _startQuestionTimer();
  }

  /// Soruları oyuncunun albümündeki kartlardan üretir.
  QuizEngine _buildEngine() {
    final collection = CardCollectionScope.of(context);
    return QuizEngine(
      deck: collection.deck,
      collectedIds: {
        for (final card in collection.deck)
          if (collection.isCollected(card.id)) card.id,
      },
    );
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _clock?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Zamanlayıcılar
  // ---------------------------------------------------------------------------

  void _startClock() {
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      _totalElapsed += const Duration(seconds: 1);
    });
  }

  void _startQuestionTimer() {
    _remainingSeconds = QuizEngine.timePerQuestion;
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        // Süre doldu — cevapsız geçir.
        _handleTimeout();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Oyun akışı
  // ---------------------------------------------------------------------------

  void _selectOption(int index) {
    if (_answered) return;
    HapticFeedback.lightImpact();
    setState(() => _selected = index);
  }

  void _confirmAnswer() {
    if (_selected < 0 || _answered) return;
    _questionTimer?.cancel();
    HapticFeedback.mediumImpact();

    final correct = _engine.answer(_selected, _remainingSeconds);
    setState(() {
      _answered = true;
      _wasCorrect = correct;
    });
  }

  void _handleTimeout() {
    _questionTimer?.cancel();
    // Süre dolunca otomatik yanlış sayılır.
    _engine.answer(-1, 0);
    setState(() {
      _answered = true;
      _wasCorrect = false;
    });
  }

  Future<void> _nextQuestion() async {
    _engine.next();

    if (_engine.isFinished) {
      await _handleGameOver();
      return;
    }

    // Geçiş animasyonu
    _slideController.reset();
    setState(() {
      _selected = -1;
      _answered = false;
      _wasCorrect = false;
    });
    _startQuestionTimer();
    _slideController.forward();
  }

  Future<void> _handleGameOver() async {
    _clock?.cancel();
    _questionTimer?.cancel();
    HapticFeedback.heavyImpact();

    final summary = GameSummary(
      kind: GameKind.quiz,
      points: _engine.totalPoints,
      stars: _engine.starsEarned,
      elapsed: _totalElapsed,
      stats: [
        GameStat(
          icon: Icons.check_circle_rounded,
          label: 'Doğru',
          value: '${_engine.correctCount}',
        ),
        GameStat(
          icon: Icons.close_rounded,
          label: 'Yanlış',
          value: '${_engine.questionCount - _engine.correctCount}',
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
      if (mounted) _restartGame();
    } else if (mounted) {
      Navigator.of(context).pop(_engine.starsEarned);
    }
  }

  void _restartGame() {
    _clock?.cancel();
    _questionTimer?.cancel();
    _slideController.reset();

    setState(() {
      _engine = _buildEngine();
      _selected = -1;
      _answered = false;
      _wasCorrect = false;
      _totalElapsed = Duration.zero;
    });

    _startClock();
    _startQuestionTimer();
    _slideController.forward();
  }

  Future<void> _handleBack() async {
    if (_engine.isFinished || await confirmExitGame(context)) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ---------------------------------------------------------------------------
  // Görünüm
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final q = _engine.isFinished ? null : _engine.currentQuestion;
    final progress = _engine.questionCount == 0
        ? 0.0
        : (_engine.currentIndex + 1) / _engine.questionCount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── App Bar ──
              _QuizAppBar(
                onBack: _handleBack,
                remainingSeconds: _remainingSeconds,
                isTimerActive: !_answered && q != null,
              ),

              // ── İçerik ──
              Expanded(
                child: q == null
                    ? const SizedBox.shrink()
                    : SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.marginMobile,
                              AppSpacing.base,
                              AppSpacing.marginMobile,
                              AppSpacing.gutter,
                            ),
                            children: [
                              // ── İlerleme ──
                              _ProgressSection(
                                current: _engine.currentIndex + 1,
                                total: _engine.questionCount,
                                points: _engine.totalPoints,
                                progress: progress,
                              ),
                              const SizedBox(height: AppSpacing.base * 2),

                              // ── Soru kartı ──
                              _QuestionCard(
                                emoji: q.card.emoji,
                                question: q.questionText,
                                category: q.card.category,
                                cardTitle: q.card.title,
                                isReview: q.isReview,
                              ),
                              const SizedBox(height: AppSpacing.base * 2.5),

                              // ── Şıklar ──
                              for (var i = 0; i < q.options.length; i++) ...[
                                _OptionButton(
                                  index: i,
                                  text: q.options[i],
                                  selected: _selected == i,
                                  answered: _answered,
                                  isCorrect: i == q.correctIndex,
                                  onTap: () => _selectOption(i),
                                ),
                                if (i < q.options.length - 1)
                                  const SizedBox(height: AppSpacing.base * 1.5),
                              ],

                              // ── Doğru/yanlış geri bildirim ──
                              if (_answered) ...[
                                const SizedBox(height: AppSpacing.base * 2),
                                _FeedbackBanner(
                                  correct: _wasCorrect,
                                  correctAnswer: q.correctAnswer,
                                  explanation: q.explanation,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.base * 2),
                            ],
                          ),
                        ),
                      ),
              ),

              // ── Alt buton ──
              _BottomAction(
                answered: _answered,
                hasSelection: _selected >= 0,
                isLast:
                    _engine.currentIndex >= _engine.questionCount - 1,
                onConfirm: _confirmAnswer,
                onNext: _nextQuestion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// App Bar
// =============================================================================

class _QuizAppBar extends StatelessWidget {
  const _QuizAppBar({
    required this.onBack,
    required this.remainingSeconds,
    required this.isTimerActive,
  });

  final VoidCallback onBack;
  final int remainingSeconds;
  final bool isTimerActive;

  @override
  Widget build(BuildContext context) {
    final seconds = remainingSeconds.clamp(0, 99);
    final urgent = seconds <= 5 && isTimerActive;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 6,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Geri butonu
          GestureDetector(
            key: const ValueKey('quiz_back'),
            onTap: onBack,
            child: Container(
              height: AppSpacing.touchTarget,
              width: AppSpacing.touchTarget,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),

          // Başlık
          Expanded(
            child: Text(
              'Bilgi Yarışması',
              textAlign: TextAlign.center,
              style: AppText.headlineMd.copyWith(color: AppColors.primary),
            ),
          ),

          // Süre göstergesi
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: urgent
                  ? AppColors.errorContainer
                  : AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: urgent ? AppColors.error : AppColors.foxOrange,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_rounded,
                  size: 18,
                  color: urgent
                      ? AppColors.onErrorContainer
                      : AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  '00:${seconds.toString().padLeft(2, '0')}',
                  style: AppText.labelLg.copyWith(
                    color: urgent
                        ? AppColors.onErrorContainer
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
    required this.current,
    required this.total,
    required this.points,
    required this.progress,
  });

  final int current;
  final int total;
  final int points;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Soru $current / $total',
              style: AppText.labelLg.copyWith(
                color: AppColors.secondary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.sunnyYellow,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$points Puan',
                  style: AppText.labelLg.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.sunnyYellow, AppColors.foxOrange],
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
// Soru kartı
// =============================================================================

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.emoji,
    required this.question,
    required this.category,
    required this.cardTitle,
    required this.isReview,
  });

  final String emoji;
  final String question;
  final CardCategory category;

  /// Sorunun geldiği bilgi kartının adı — oyuncu soruyu kartla eşleştirebilsin.
  final String cardTitle;

  /// Kart albümde mi? Değilse soru yeni bir bilgi öğretiyor demektir.
  final bool isReview;

  @override
  Widget build(BuildContext context) {
    return DepthBox(
      color: AppColors.creamBg,
      depthColor: AppColors.surfaceContainerHighest,
      borderColor: category.accent,
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: category.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 10),

          // Hangi karttan geldiğini gösteren çip.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: category.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isReview ? Icons.style_rounded : Icons.auto_awesome_rounded,
                  size: 15,
                  color: category.accent,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isReview ? cardTitle : '$cardTitle · yeni bilgi',
                    overflow: TextOverflow.ellipsis,
                    style: AppText.labelSm.copyWith(color: category.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Text(
            question,
            textAlign: TextAlign.center,
            style: AppText.headlineMd.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Şık butonu
// =============================================================================

const _optionLetters = ['A', 'B', 'C', 'D'];

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.index,
    required this.text,
    required this.selected,
    required this.answered,
    required this.isCorrect,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final bool answered;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Duruma göre renkler
    Color bg;
    Color border;
    Color letterBg;
    Color letterColor;
    Color textColor;
    IconData? trailingIcon;
    Color? trailingColor;

    if (answered && isCorrect) {
      // Doğru cevap — her zaman yeşil göster
      bg = AppColors.leafGreen.withValues(alpha: 0.15);
      border = AppColors.leafGreen;
      letterBg = AppColors.leafGreen;
      letterColor = Colors.white;
      textColor = AppColors.onSurface;
      trailingIcon = Icons.check_circle_rounded;
      trailingColor = AppColors.leafGreen;
    } else if (answered && selected && !isCorrect) {
      // Yanlış seçilmiş
      bg = AppColors.berryPink.withValues(alpha: 0.12);
      border = AppColors.berryPink;
      letterBg = AppColors.berryPink;
      letterColor = Colors.white;
      textColor = AppColors.onSurface;
      trailingIcon = Icons.cancel_rounded;
      trailingColor = AppColors.berryPink;
    } else if (!answered && selected) {
      // Seçili ama henüz onaylanmadı
      bg = AppColors.primaryFixed;
      border = AppColors.foxOrange;
      letterBg = AppColors.foxOrange;
      letterColor = Colors.white;
      textColor = AppColors.onSurface;
    } else {
      // Varsayılan
      bg = AppColors.creamBg;
      border = AppColors.outlineVariant;
      letterBg = Colors.transparent;
      letterColor = AppColors.onSurfaceVariant;
      textColor = AppColors.onSurface;
    }

    // Cevaplandıktan sonra sadece doğru ve seçilen yanlış gösterilir;
    // diğerleri soluk olur.
    final dimmed = answered && !isCorrect && !selected;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dimmed ? 0.4 : 1.0,
      child: Squishy(
        onTap: answered ? null : onTap,
        color: bg,
        depthColor: border.withValues(alpha: 0.4),
        borderColor: border,
        radius: AppRadius.md,
        depth: 5,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Harf dairesi
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: letterBg,
                shape: BoxShape.circle,
                border: letterBg == Colors.transparent
                    ? Border.all(color: AppColors.outlineVariant, width: 2)
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                _optionLetters[index],
                style: AppText.labelLg.copyWith(color: letterColor),
              ),
            ),
            const SizedBox(width: 14),
            // Şık metni
            Expanded(
              child: Text(
                text,
                style: AppText.bodyLg.copyWith(color: textColor),
              ),
            ),
            // Sonuç ikonu
            if (trailingIcon != null) ...[
              const SizedBox(width: 8),
              Icon(trailingIcon, color: trailingColor, size: 26),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Doğru / Yanlış geri bildirim
// =============================================================================

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
  });

  final bool correct;

  /// Doğru şıkkın metni — yanlış cevaplandığında gösterilir.
  final String correctAnswer;

  /// Kartın kendi anlatımı; doğru da olsa yanlış da olsa gösterilir ki bilgi
  /// pekişsin.
  final String explanation;

  @override
  Widget build(BuildContext context) {
    return DepthBox(
      color: correct
          ? AppColors.leafGreen.withValues(alpha: 0.12)
          : AppColors.berryPink.withValues(alpha: 0.10),
      depthColor: correct
          ? AppColors.leafGreen.withValues(alpha: 0.3)
          : AppColors.berryPink.withValues(alpha: 0.25),
      borderColor: correct ? AppColors.leafGreen : AppColors.berryPink,
      radius: AppRadius.md,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.emoji_events_rounded : Icons.lightbulb_rounded,
            color: correct ? AppColors.leafGreen : AppColors.berryPink,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? 'Harika, doğru cevap! 🎉' : 'Doğru cevap:',
                  style: AppText.labelLg.copyWith(
                    color: correct
                        ? AppColors.leafGreen
                        : AppColors.berryPink,
                  ),
                ),
                if (!correct) ...[
                  const SizedBox(height: 4),
                  Text(
                    correctAnswer,
                    style: AppText.labelLg.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  explanation,
                  style: AppText.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
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

// =============================================================================
// Alt buton
// =============================================================================

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.answered,
    required this.hasSelection,
    required this.isLast,
    required this.onConfirm,
    required this.onNext,
  });

  final bool answered;
  final bool hasSelection;
  final bool isLast;
  final VoidCallback onConfirm;
  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    final enabled = answered || hasSelection;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.md),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.marginMobile,
            14,
            AppSpacing.marginMobile,
            12,
          ),
          child: Squishy(
            key: ValueKey(answered ? 'quiz_next' : 'quiz_confirm'),
            onTap: enabled
                ? (answered ? onNext : onConfirm)
                : null,
            color: enabled ? AppColors.foxOrange : AppColors.surfaceContainer,
            depthColor: enabled
                ? AppColors.primary
                : AppColors.surfaceContainerHigh,
            radius: AppRadius.md,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    answered
                        ? (isLast ? 'SONUÇLARI GÖR' : 'SONRAKİ SORU')
                        : 'CEVABI KONTROL ET',
                    style: AppText.labelLg.copyWith(
                      color: enabled
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                  if (answered) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
