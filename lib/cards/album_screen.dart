import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/squishy.dart';
import 'card_collection.dart';
import 'card_detail_screen.dart';
import 'card_widgets.dart';
import 'info_card.dart';

/// Bilgi albümü: toplanan kartlar renkli, kazanılmayanlar kilitli görünür.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  /// null = "Hepsi" filtresi.
  CardCategory? _filter;

  void _openCard(InfoCard card, {required bool unlocked}) {
    if (!unlocked) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            content: Text(
              'Bu kartı oyun oynayarak kazanabilirsin!',
              style: AppText.labelLg.copyWith(color: Colors.white),
            ),
          ),
        );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CardDetailScreen(card: card)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collection = CardCollectionScope.of(context);
    final cards = collection.byCategory(_filter);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _AlbumHeader(onBack: () => Navigator.of(context).pop()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                  ),
                  child: DepthBox(
                    color: AppColors.secondaryContainer,
                    depthColor: const Color(0xFF8FC9C8),
                    borderColor: AppColors.bandanaTeal,
                    radius: AppRadius.md,
                    padding: const EdgeInsets.all(16),
                    child: CollectionProgressBar(
                      collected: collection.collectedCount,
                      total: collection.total,
                      label: 'Toplam koleksiyon',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.base * 2),
                _FilterBar(
                  selected: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: AppSpacing.base * 1.5),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      4,
                      AppSpacing.marginMobile,
                      AppSpacing.gutter,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final unlocked = collection.isCollected(card.id);
                      return _AlbumTile(
                        card: card,
                        unlocked: unlocked,
                        onTap: () => _openCard(card, unlocked: unlocked),
                      );
                    },
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

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, AppSpacing.marginMobile, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              height: AppSpacing.touchTarget,
              width: AppSpacing.touchTarget,
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Bilgi Albümü',
              style: AppText.headlineLg.copyWith(color: AppColors.primary),
            ),
          ),
          const Mascot(size: 52),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final CardCategory? selected;
  final ValueChanged<CardCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Row(
        children: [
          _FilterChip(
            label: 'Hepsi',
            accent: AppColors.foxOrange,
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final category in CardCategory.values) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: category.label,
              accent: category.accent,
              active: selected == category,
              onTap: () => onChanged(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.accent,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squishy(
      onTap: onTap,
      color: active ? accent : AppColors.creamBg,
      depthColor: accent.withValues(alpha: active ? 0.75 : 0.3),
      borderColor: active ? accent : AppColors.outlineVariant,
      radius: 999,
      depth: 4,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Text(
        label,
        style: AppText.labelLg.copyWith(
          color: active ? Colors.white : AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AlbumTile extends StatelessWidget {
  const _AlbumTile({
    required this.card,
    required this.unlocked,
    required this.onTap,
  });

  final InfoCard card;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squishy(
      key: ValueKey('album_${card.id}'),
      onTap: onTap,
      color: unlocked ? AppColors.creamBg : AppColors.surfaceContainerHigh,
      depthColor: unlocked
          ? card.category.accent.withValues(alpha: 0.4)
          : AppColors.outlineVariant,
      borderColor: unlocked
          ? card.category.accent.withValues(alpha: 0.5)
          : AppColors.outlineVariant,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: unlocked
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: CardIllustration(
                          card: card,
                          height: double.infinity,
                          emojiSize: 52,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: card.category.accent,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppColors.outline,
                      size: 30,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            unlocked ? card.title : '???',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.labelLg.copyWith(
              color: unlocked ? AppColors.onSurface : AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}
