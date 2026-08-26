import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'info_card.dart';

/// Kartın görsel paneli: kategori renginde zemin ve büyük emoji.
class CardIllustration extends StatelessWidget {
  const CardIllustration({
    super.key,
    required this.card,
    this.height = 180,
    this.emojiSize = 92,
  });

  final InfoCard card;
  final double height;
  final double emojiSize;

  @override
  Widget build(BuildContext context) {
    final accent = card.category.accent;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Köşe noktaları — mockup'taki dekoratif detay.
          for (final alignment in const [
            Alignment.topLeft,
            Alignment.topRight,
            Alignment.bottomLeft,
            Alignment.bottomRight,
          ])
            Align(
              alignment: alignment,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          Center(
            child: Text(card.emoji, style: TextStyle(fontSize: emojiSize)),
          ),
        ],
      ),
    );
  }
}

/// Kategori etiketi.
class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.compact = false});

  final CardCategory category;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: category.accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: category.accent.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: compact ? 13 : 15, color: category.accent),
          const SizedBox(width: 4),
          Text(
            category.label,
            style: AppText.labelSm.copyWith(color: category.accent),
          ),
        ],
      ),
    );
  }
}

/// "Biliyor muydun?" bölümü — yıldız işaretli bilgi maddeleri.
class FactList extends StatelessWidget {
  const FactList({super.key, required this.facts});

  final List<String> facts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb_rounded,
              size: 20,
              color: AppColors.foxOrange,
            ),
            const SizedBox(width: 6),
            Text(
              'Biliyor muydun?',
              style: AppText.titleMd.copyWith(color: AppColors.onSurface),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final fact in facts) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 20,
                  color: AppColors.sunnyYellow,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fact,
                    style: AppText.bodyMd.copyWith(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Albüm ilerleme çubuğu: "24 / 60 kart".
class CollectionProgressBar extends StatelessWidget {
  const CollectionProgressBar({
    super.key,
    required this.collected,
    required this.total,
    required this.label,
    this.onSurface = AppColors.secondary,
    this.trackColor = Colors.white,
  });

  final int collected;
  final int total;
  final String label;
  final Color onSurface;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (collected / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppText.labelLg.copyWith(color: onSurface),
              ),
            ),
            Text(
              '$collected / $total kart',
              style: AppText.labelLg.copyWith(color: onSurface),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(height: 14, color: trackColor.withValues(alpha: 0.8)),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                widthFactor: ratio.toDouble(),
                child: Container(
                  height: 14,
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
