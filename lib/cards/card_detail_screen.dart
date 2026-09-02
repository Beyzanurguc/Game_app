import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/squishy.dart';
import 'card_widgets.dart';
import 'info_card.dart';

/// Albümden açılan kart detayı.
class CardDetailScreen extends StatelessWidget {
  const CardDetailScreen({super.key, required this.card});

  final InfoCard card;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                  child: Row(
                    children: [
                      BackTapTarget(
                        onTap: () => Navigator.of(context).pop(),
                        color: AppColors.primary,
                      ),
                      const Spacer(),
                      CategoryChip(category: card.category),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      8,
                      AppSpacing.marginMobile,
                      AppSpacing.gutter,
                    ),
                    children: [
                      Text(
                        card.title,
                        textAlign: TextAlign.center,
                        style: AppText.headlineLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base * 1.5),
                      CardIllustration(card: card, height: 200),
                      const SizedBox(height: AppSpacing.base * 2),
                      DepthBox(
                        color: AppColors.creamBg,
                        depthColor: AppColors.surfaceContainerHighest,
                        borderColor: AppColors.outlineVariant,
                        radius: AppRadius.md,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.question,
                              style: AppText.titleMd.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              card.answer,
                              style: AppText.bodyLg.copyWith(
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base * 2),
                      FactList(facts: card.facts),
                      const SizedBox(height: AppSpacing.base),
                      Squishy(
                        onTap: () => Navigator.of(context).pop(),
                        color: AppColors.foxOrange,
                        depthColor: AppColors.primary,
                        radius: AppRadius.md,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'HARİKA, ÖĞRENDİM!',
                                style: AppText.labelLg.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
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
    );
  }
}
