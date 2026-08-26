import 'package:flutter/material.dart';

import '../games/game_summary.dart';
import '../settings/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/squishy.dart';
import 'card_collection.dart';
import 'card_widgets.dart';
import 'info_card.dart';

/// Ödül ekranından çıkış yönü.
enum RewardExit { home, replay }

/// Oyun sonunda kazanılan bilgi kartını gösteren ekran.
///
/// Kart kaydedilmeden çıkılmak istenirse önce uyarı gösterilir.
///
/// [isNew] false olduğunda albümdeki bütün kartlar toplanmıştır: kart yeni
/// gibi sunulmaz, "yeni kartlar yakında" mesajıyla bir tekrar bilgisi olur.
class RewardCardScreen extends StatefulWidget {
  const RewardCardScreen({
    super.key,
    required this.card,
    required this.summary,
    this.isNew = true,
  });

  final InfoCard card;
  final GameSummary summary;
  final bool isNew;

  @override
  State<RewardCardScreen> createState() => _RewardCardScreenState();
}

class _RewardCardScreenState extends State<RewardCardScreen> {
  /// Tekrar kartı zaten albümde olduğu için baştan kaydedilmiş sayılır.
  late bool _saved = !widget.isNew;
  bool _factsVisible = false;

  void _saveCard() {
    if (_saved) return;
    CardCollectionScope.of(context).save(widget.card);
    setState(() {
      _saved = true;
      _factsVisible = true;
    });
  }

  Future<void> _leave(RewardExit exit) async {
    if (!_saved) {
      final action = await showDialog<_UnsavedAction>(
        context: context,
        builder: (context) => const _UnsavedCardDialog(),
      );
      if (!mounted || action == null) return;

      if (action == _UnsavedAction.takeCard) {
        _saveCard();
        return;
      }
    }
    if (mounted) Navigator.of(context).pop(exit);
  }

  @override
  Widget build(BuildContext context) {
    final collection = CardCollectionScope.of(context);
    final settings = AppSettingsScope.of(context);
    final card = widget.card;
    final summary = widget.summary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave(RewardExit.home);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _ScorePanel(
              summary: summary,
              collected: collection.collectedCount,
              total: collection.total,
              onClose: () => _leave(RewardExit.home),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.marginMobile,
                  AppSpacing.base * 2,
                  AppSpacing.marginMobile,
                  AppSpacing.gutter,
                ),
                children: [
                  Center(child: Mascot(size: 128, key: ValueKey(_saved))),
                  const SizedBox(height: AppSpacing.base * 2),
                  if (!widget.isNew) ...[
                    const _DeckCompleteBanner(),
                    const SizedBox(height: AppSpacing.base * 1.5),
                  ],
                  DepthBox(
                    color: AppColors.creamBg,
                    depthColor: AppColors.surfaceContainerHighest,
                    borderColor: _saved
                        ? AppColors.bandanaTeal
                        : AppColors.foxOrange,
                    radius: AppRadius.lg,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CategoryChip(category: card.category),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _StatusLabel(
                                  isNew: widget.isNew,
                                  saved: _saved,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CardIllustration(card: card, height: 150),
                        const SizedBox(height: 14),
                        Text(
                          card.question,
                          style: AppText.headlineMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.answer,
                          style: AppText.bodyLg.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (!_factsVisible)
                          GestureDetector(
                            onTap: () => setState(() => _factsVisible = true),
                            child: Row(
                              children: [
                                Text(
                                  'Biraz daha anlat',
                                  style: AppText.labelLg.copyWith(
                                    color: AppColors.secondary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.secondary,
                                  ),
                                ),
                                const Icon(
                                  Icons.expand_more_rounded,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: _factsVisible
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: FactList(facts: card.facts),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base * 2),
                  _StatsRow(summary: summary),
                ],
              ),
            ),
            // Butonlar sabit: kaydet düğmesi hiçbir zaman ekran dışında kalmaz.
            _ActionArea(
              saved: _saved,
              // Günlük hak bittiyse tekrar oynama düğmesi hiç gösterilmez.
              canReplay: settings.canPlay,
              onPrimary: _saved ? () => _leave(RewardExit.home) : _saveCard,
              onReplay: () => _leave(RewardExit.replay),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alt sabit buton alanı.
class _ActionArea extends StatelessWidget {
  const _ActionArea({
    required this.saved,
    required this.canReplay,
    required this.onPrimary,
    required this.onReplay,
  });

  final bool saved;

  /// Günlük oyun hakkı kaldı mı?
  final bool canReplay;

  final VoidCallback onPrimary;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
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
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Squishy(
                  key: const ValueKey('reward_primary'),
                  onTap: onPrimary,
                  color: AppColors.foxOrange,
                  depthColor: AppColors.primary,
                  radius: AppRadius.md,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text(
                      saved ? 'ANA SAYFA' : 'KARTI KAYDET',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.labelLg.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              if (canReplay) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Squishy(
                    key: const ValueKey('reward_replay'),
                    onTap: onReplay,
                    color: AppColors.creamBg,
                    depthColor: AppColors.surfaceContainerHighest,
                    borderColor: AppColors.foxOrange,
                    radius: AppRadius.md,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Center(
                      child: Text(
                        'TEKRAR OYNA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.labelLg.copyWith(
                          color: AppColors.foxOrange,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Üstteki skor ve albüm ilerleme paneli.
class _ScorePanel extends StatelessWidget {
  const _ScorePanel({
    required this.summary,
    required this.collected,
    required this.total,
    required this.onClose,
  });

  final GameSummary summary;
  final int collected;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, AppSpacing.gutter, 18),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    key: const ValueKey('reward_close'),
                    onTap: onClose,
                    child: Container(
                      height: AppSpacing.touchTarget,
                      width: AppSpacing.touchTarget,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Skorun: ${summary.points}',
                      textAlign: TextAlign.center,
                      style: AppText.headlineMd.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.sunnyYellow,
                        size: 24,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '+${summary.stars}',
                        style: AppText.labelLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              CollectionProgressBar(
                collected: collected,
                total: total,
                label: 'Bilgi albümün',
                onSurface: AppColors.onPrimaryFixedVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartın sağ üst köşesindeki durum etiketi.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.isNew, required this.saved});

  final bool isNew;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    if (!isNew) {
      return const _PillBadge(
        icon: Icons.replay_rounded,
        label: 'Albümünde vardı',
      );
    }
    if (saved) {
      return const _PillBadge(
        icon: Icons.check_circle_rounded,
        label: 'Albümüne eklendi',
      );
    }
    return Text(
      'Yeni kart!',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.labelSm.copyWith(color: AppColors.foxOrange),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.secondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.labelSm.copyWith(color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deste bitince kartın üstünde gösterilen bilgi kutusu.
class _DeckCompleteBanner extends StatelessWidget {
  const _DeckCompleteBanner();

  @override
  Widget build(BuildContext context) {
    return DepthBox(
      color: AppColors.secondaryContainer,
      depthColor: const Color(0xFF8FC9C8),
      borderColor: AppColors.bandanaTeal,
      radius: AppRadius.md,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: AppColors.secondary,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yeni kartlar yakında yüklenecek',
                  style: AppText.labelLg.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Albümdeki bütün kartları topladın! Yenileri gelene kadar '
                  'eski kartlarından biriyle bilgi tazeleyelim.',
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});

  final GameSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          icon: Icons.schedule_rounded,
          label: 'Süre',
          value: summary.formattedTime,
        ),
        for (final stat in summary.stats) ...[
          const SizedBox(width: 10),
          _StatBox(icon: stat.icon, label: stat.label, value: stat.value),
        ],
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 2),
            Text(value, style: AppText.labelLg),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

enum _UnsavedAction { takeCard, leaveAnyway }

/// Kart kaydedilmeden çıkılmak istendiğinde gösterilen uyarı.
class _UnsavedCardDialog extends StatelessWidget {
  const _UnsavedCardDialog();

  @override
  Widget build(BuildContext context) {
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
              'Kartını almadan çıkıyorsun',
              textAlign: TextAlign.center,
              style: AppText.headlineMd.copyWith(color: AppColors.berryPink),
            ),
            const SizedBox(height: 6),
            Text(
              'Bu kart albümüne eklenmeyecek.',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Squishy(
              onTap: () => Navigator.of(context).pop(_UnsavedAction.takeCard),
              color: AppColors.foxOrange,
              depthColor: AppColors.primary,
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: Text(
                  'KARTI AL',
                  style: AppText.labelLg.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  Navigator.of(context).pop(_UnsavedAction.leaveAnyway),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Yine de çık',
                  style: AppText.labelLg.copyWith(color: AppColors.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
