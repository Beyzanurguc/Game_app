import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/squishy.dart';
import 'sudoku_engine.dart';

/// Zorluk seçim sayfası. Oyuna başlamadan önce ve oyun içinde aynı sayfa
/// kullanılır; seçim yapılmazsa null döner.
Future<SudokuDifficulty?> showSudokuDifficultySheet(
  BuildContext context, {
  SudokuDifficulty? current,
  String subtitle = 'Hangi seviyede oynamak istersin?',
}) {
  return showModalBottomSheet<SudokuDifficulty>(
    context: context,
    backgroundColor: AppColors.surface,
    // Kısa ekranlarda varsayılan 9/16 sınırı içeriği kesiyor; sayfa kendi
    // yüksekliğini seçsin diye serbest bırakılır.
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) =>
        _DifficultySheet(current: current, subtitle: subtitle),
  );
}

class _DifficultySheet extends StatelessWidget {
  const _DifficultySheet({required this.current, required this.subtitle});

  final SudokuDifficulty? current;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zorluk seç',
                        style: AppText.headlineMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppText.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Mascot(size: 64),
              ],
            ),
            const SizedBox(height: 16),
            for (final difficulty in SudokuDifficulty.values) ...[
              _DifficultyOption(
                difficulty: difficulty,
                selected: difficulty == current,
                onTap: () => Navigator.of(context).pop(difficulty),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _DifficultyOption extends StatelessWidget {
  const _DifficultyOption({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final SudokuDifficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  static const _accents = {
    SudokuDifficulty.kolay: AppColors.bandanaTeal,
    SudokuDifficulty.orta: AppColors.sunnyYellow,
    SudokuDifficulty.zor: AppColors.berryPink,
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accents[difficulty]!;

    return Squishy(
      onTap: onTap,
      color: selected ? accent.withValues(alpha: 0.22) : AppColors.creamBg,
      depthColor: accent.withValues(alpha: 0.4),
      borderColor: selected ? accent : AppColors.outlineVariant,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Text(
              '${difficulty.clues}',
              style: AppText.labelLg.copyWith(color: AppColors.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  difficulty.label,
                  style: AppText.titleMd.copyWith(color: AppColors.onSurface),
                ),
                Text(
                  difficulty.description,
                  style: AppText.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
            color: selected ? accent : AppColors.outline,
          ),
        ],
      ),
    );
  }
}
