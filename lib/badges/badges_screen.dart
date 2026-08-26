import 'package:flutter/material.dart';

import '../cards/card_collection.dart';
import '../profile/fox_avatar.dart';
import '../profile/player_profile.dart';
import '../theme/app_theme.dart';
import '../widgets/squishy.dart';
import 'badge_catalog.dart';

/// Rozet sayfası: kazanılanlar renkli, kalanlar ilerleme çubuğuyla kilitli.
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  /// null = "Hepsi" filtresi.
  BadgeGroup? _filter;

  /// Sayfa açıldığında yeni kazanılmış olanlar; çıkarken "görüldü" işaretlenir.
  Set<String> _fresh = const {};
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    _ready = true;

    final profile = PlayerProfileScope.of(context);
    final data = BadgeContext(
      profile: profile,
      collection: CardCollectionScope.of(context),
    );

    // Kazanılıp da daha önce görülmemiş rozetler bu turda "YENİ" etiketi alır.
    final earned = earnedBadges(data).map((status) => status.def.id);
    _fresh = earned.where((id) => !profile.hasSeenBadge(id)).toSet();
    if (_fresh.isNotEmpty) {
      // Etiket bu ziyarette görünsün; işaretleme çizimden sonra yapılır.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) profile.markBadgesSeen(_fresh);
      });
    }
  }

  void _openBadge(BadgeStatus status) {
    showDialog<void>(
      context: context,
      builder: (context) => _BadgeDialog(status: status),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = PlayerProfileScope.of(context);
    final collection = CardCollectionScope.of(context);
    final all = evaluateBadges(
      BadgeContext(profile: profile, collection: collection),
    );
    final earned = all.where((status) => status.earned).length;
    final shown = _filter == null
        ? all
        : all.where((status) => status.def.group == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _BadgesHeader(
                  profile: profile,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                  ),
                  child: _SummaryCard(
                    earned: earned,
                    total: all.length,
                    stars: profile.totalStarsEarned,
                    games: profile.gamesPlayed,
                  ),
                ),
                const SizedBox(height: AppSpacing.base * 2),
                _GroupBar(
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
                          maxCrossAxisExtent: 190,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: shown.length,
                    itemBuilder: (context, index) {
                      final status = shown[index];
                      return _BadgeTile(
                        status: status,
                        fresh: _fresh.contains(status.def.id),
                        onTap: () => _openBadge(status),
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

// ---------------------------------------------------------------------------
// Başlık ve özet
// ---------------------------------------------------------------------------

class _BadgesHeader extends StatelessWidget {
  const _BadgesHeader({required this.profile, required this.onBack});

  final PlayerProfile profile;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, AppSpacing.marginMobile, 12),
      child: Row(
        children: [
          GestureDetector(
            key: const ValueKey('badges_back'),
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
              'Rozetlerim',
              style: AppText.headlineLg.copyWith(color: AppColors.primary),
            ),
          ),
          FoxAvatar(size: 52, items: profile.equippedItems),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.earned,
    required this.total,
    required this.stars,
    required this.games,
  });

  final int earned;
  final int total;
  final int stars;
  final int games;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (earned / total).clamp(0.0, 1.0);

    return DepthBox(
      color: AppColors.secondaryContainer,
      depthColor: const Color(0xFF8FC9C8),
      borderColor: AppColors.bandanaTeal,
      radius: AppRadius.md,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kazanılan rozet',
                  style: AppText.labelLg.copyWith(color: AppColors.secondary),
                ),
              ),
              Text(
                '$earned / $total',
                key: ValueKey('badge_count_${earned}_$total'),
                style: AppText.labelLg.copyWith(color: AppColors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
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
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                icon: Icons.sports_esports_rounded,
                label: 'Oynanan oyun',
                value: '$games',
              ),
              const SizedBox(width: 10),
              _MiniStat(
                icon: Icons.star_rounded,
                label: 'Toplam yıldız',
                value: '$stars',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.secondary),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filtre ve rozet kutuları
// ---------------------------------------------------------------------------

class _GroupBar extends StatelessWidget {
  const _GroupBar({required this.selected, required this.onChanged});

  final BadgeGroup? selected;
  final ValueChanged<BadgeGroup?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Row(
        children: [
          _GroupChip(
            keyValue: 'badge_group_all',
            label: 'Hepsi',
            accent: AppColors.foxOrange,
            active: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final group in BadgeGroup.values) ...[
            const SizedBox(width: 8),
            _GroupChip(
              keyValue: 'badge_group_${group.name}',
              label: group.label,
              accent: group.accent,
              active: selected == group,
              onTap: () => onChanged(group),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.keyValue,
    required this.label,
    required this.accent,
    required this.active,
    required this.onTap,
  });

  final String keyValue;
  final String label;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squishy(
      key: ValueKey(keyValue),
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

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.status,
    required this.fresh,
    required this.onTap,
  });

  final BadgeStatus status;

  /// Bu ziyarette ilk kez kazanılmış görünüyor.
  final bool fresh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final earned = status.earned;
    final accent = status.def.accent;

    return Squishy(
      key: ValueKey('badge_${status.def.id}'),
      onTap: onTap,
      color: earned ? AppColors.creamBg : AppColors.surfaceContainerHigh,
      depthColor: earned
          ? accent.withValues(alpha: 0.45)
          : AppColors.outlineVariant,
      borderColor: earned
          ? accent.withValues(alpha: 0.6)
          : AppColors.outlineVariant,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                BadgeMedal(status: status, size: 78),
                if (fresh)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.berryPink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'YENİ',
                        style: AppText.labelSm.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status.def.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.labelLg.copyWith(
              color: earned ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          if (earned)
            Text('Kazanıldı', style: AppText.labelSm.copyWith(color: accent))
          else
            _ProgressPill(status: status),
        ],
      ),
    );
  }
}

/// Rozet madalyası: kazanılınca renkli halka, kilitliyken gri.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.status, required this.size});

  final BadgeStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final earned = status.earned;
    final accent = status.def.accent;

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dış halka ilerlemeyi de gösterir.
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              value: status.ratio,
              strokeWidth: size * 0.075,
              backgroundColor: AppColors.outlineVariant.withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation(
                earned ? accent : accent.withValues(alpha: 0.55),
              ),
            ),
          ),
          Container(
            height: size * 0.74,
            width: size * 0.74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: earned
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: 0.95),
                        accent.withValues(alpha: 0.65),
                      ],
                    )
                  : null,
              color: earned ? null : AppColors.surfaceContainerHighest,
            ),
            child: Icon(
              earned ? status.def.icon : Icons.lock_rounded,
              size: size * 0.38,
              color: earned ? Colors.white : AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.status});

  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '${status.progress} / ${status.target}',
        style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rozet ayrıntısı
// ---------------------------------------------------------------------------

class _BadgeDialog extends StatelessWidget {
  const _BadgeDialog({required this.status});

  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final earned = status.earned;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: DepthBox(
        color: AppColors.creamBg,
        depthColor: AppColors.surfaceContainerHighest,
        borderColor: status.def.accent,
        radius: AppRadius.lg,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BadgeMedal(status: status, size: 110),
            const SizedBox(height: 10),
            Text(
              status.def.title,
              textAlign: TextAlign.center,
              style: AppText.headlineMd.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              status.def.description,
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: earned
                    ? status.def.accent.withValues(alpha: 0.16)
                    : AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                earned ? 'Kazanıldı!' : '${status.progress} / ${status.target}',
                style: AppText.labelLg.copyWith(
                  color: earned
                      ? status.def.accent
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Squishy(
              key: const ValueKey('badge_close'),
              onTap: () => Navigator.of(context).pop(),
              color: AppColors.foxOrange,
              depthColor: AppColors.primary,
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'TAMAM',
                  style: AppText.labelLg.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
