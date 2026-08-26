import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../cards/card_collection.dart';
import '../theme/app_theme.dart';
import '../widgets/squishy.dart';
import 'fox_avatar.dart';
import 'fox_items.dart';
import 'player_profile.dart';

/// Tilki Atölyesi: yıldızlarla aksesuar alınır ve maskota takılır.
class FoxWorkshopScreen extends StatefulWidget {
  const FoxWorkshopScreen({super.key});

  @override
  State<FoxWorkshopScreen> createState() => _FoxWorkshopScreenState();
}

class _FoxWorkshopScreenState extends State<FoxWorkshopScreen> {
  FoxSlot _slot = FoxSlot.hat;

  Future<void> _tapItem(FoxItem item) async {
    final profile = PlayerProfileScope.of(context);
    final wallet = CardCollectionScope.of(context);

    // Sahip olunan aksesuar takılır ya da çıkarılır.
    if (profile.owns(item.id)) {
      HapticFeedback.selectionClick();
      profile.toggleEquip(item);
      return;
    }

    if (wallet.stars < item.price) {
      _tell('${item.price - wallet.stars} yıldız daha lazım!', short: true);
      return;
    }

    final buy = await showDialog<bool>(
      context: context,
      builder: (context) => _BuyDialog(item: item, balance: wallet.stars),
    );
    if (buy != true || !mounted) return;

    // Bakiye kontrolü satın alma anında yeniden yapılır.
    if (!wallet.spendStars(item.price)) return;
    profile.unlock(item);
    HapticFeedback.mediumImpact();
    _tell('${item.name} tilkiye çok yakıştı!');
  }

  void _removeSlot() {
    HapticFeedback.selectionClick();
    PlayerProfileScope.of(context).clearSlot(_slot);
  }

  void _tell(String message, {bool short = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: short ? AppColors.secondary : AppColors.foxOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          content: Text(
            message,
            style: AppText.labelLg.copyWith(color: Colors.white),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final profile = PlayerProfileScope.of(context);
    final wallet = CardCollectionScope.of(context);
    final items = foxItemsFor(_slot);
    final equipped = profile.equippedIn(_slot);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _WorkshopHeader(
                  stars: wallet.stars,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.marginMobile,
                  ),
                  child: _Stage(profile: profile),
                ),
                const SizedBox(height: AppSpacing.base * 2),
                _SlotBar(
                  selected: _slot,
                  onChanged: (slot) => setState(() => _slot = slot),
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
                          childAspectRatio: 0.74,
                        ),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      // İlk kutu bölgeyi boşaltır.
                      if (index == 0) {
                        return _RemoveTile(
                          slot: _slot,
                          active: equipped == null,
                          onTap: _removeSlot,
                        );
                      }

                      final item = items[index - 1];
                      return _ItemTile(
                        item: item,
                        owned: profile.owns(item.id),
                        equipped: profile.isEquipped(item),
                        affordable: wallet.stars >= item.price,
                        onTap: () => _tapItem(item),
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
// Başlık ve sahne
// ---------------------------------------------------------------------------

class _WorkshopHeader extends StatelessWidget {
  const _WorkshopHeader({required this.stars, required this.onBack});

  final int stars;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, AppSpacing.marginMobile, 12),
      child: Row(
        children: [
          GestureDetector(
            key: const ValueKey('workshop_back'),
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
              'Tilki Atölyesi',
              style: AppText.headlineLg.copyWith(color: AppColors.primary),
            ),
          ),
          StarBalance(stars: stars),
        ],
      ),
    );
  }
}

/// Yıldız bakiyesi hapı — atölyede ve rozet sayfasında kullanılır.
class StarBalance extends StatelessWidget {
  const StarBalance({super.key, required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.sunnyYellow.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.sunnyYellow, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFE9A800), size: 20),
          const SizedBox(width: 5),
          Text(
            '$stars',
            key: ValueKey('star_balance_$stars'),
            style: AppText.labelLg,
          ),
        ],
      ),
    );
  }
}

/// Tilkinin takılı aksesuarlarıyla göründüğü sahne.
class _Stage extends StatelessWidget {
  const _Stage({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final equipped = profile.equippedItems;

    return DepthBox(
      color: AppColors.creamBg,
      depthColor: AppColors.surfaceContainerHighest,
      borderColor: AppColors.sunnyYellow,
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sahne halkası: tilkinin arkasında yumuşak bir daire.
                Container(
                  height: 150,
                  width: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.sunnyYellow.withValues(alpha: 0.35),
                        AppColors.sunnyYellow.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                FoxAvatar(size: 186, items: equipped),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (equipped.isEmpty)
            Text(
              'Tilkiyi süslemeye hazır!',
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                for (final item in equipped)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      item.name,
                      style: AppText.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bölge seçimi ve aksesuar kutuları
// ---------------------------------------------------------------------------

class _SlotBar extends StatelessWidget {
  const _SlotBar({required this.selected, required this.onChanged});

  final FoxSlot selected;
  final ValueChanged<FoxSlot> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.marginMobile),
      child: Row(
        children: [
          for (final slot in FoxSlot.values) ...[
            if (slot != FoxSlot.values.first) const SizedBox(width: 8),
            Squishy(
              key: ValueKey('shop_slot_${slot.name}'),
              onTap: () => onChanged(slot),
              color: slot == selected ? AppColors.foxOrange : AppColors.creamBg,
              depthColor: AppColors.foxOrange.withValues(
                alpha: slot == selected ? 0.75 : 0.3,
              ),
              borderColor: slot == selected
                  ? AppColors.foxOrange
                  : AppColors.outlineVariant,
              radius: 999,
              depth: 4,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    slot.icon,
                    size: 18,
                    color: slot == selected
                        ? Colors.white
                        : AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    slot.label,
                    style: AppText.labelLg.copyWith(
                      color: slot == selected
                          ? Colors.white
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemoveTile extends StatelessWidget {
  const _RemoveTile({
    required this.slot,
    required this.active,
    required this.onTap,
  });

  final FoxSlot slot;

  /// Bölge zaten boşsa kutu seçili görünür.
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squishy(
      key: const ValueKey('shop_remove'),
      onTap: onTap,
      color: active ? AppColors.secondaryContainer : AppColors.creamBg,
      depthColor: active
          ? const Color(0xFF8FC9C8)
          : AppColors.surfaceContainerHighest,
      borderColor: active ? AppColors.bandanaTeal : AppColors.outlineVariant,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block_rounded,
            size: 40,
            color: active ? AppColors.secondary : AppColors.outline,
          ),
          const SizedBox(height: 10),
          Text(
            'Yok',
            style: AppText.labelLg.copyWith(
              color: active ? AppColors.secondary : AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${slot.label} takma',
            textAlign: TextAlign.center,
            style: AppText.labelSm.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.affordable,
    required this.onTap,
  });

  final FoxItem item;
  final bool owned;
  final bool equipped;

  /// Yıldız bakiyesi bu aksesuara yetiyor mu?
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = !owned && !affordable;

    return Squishy(
      key: ValueKey('shop_item_${item.id}'),
      onTap: onTap,
      color: equipped ? item.color.withValues(alpha: 0.18) : AppColors.creamBg,
      depthColor: equipped
          ? item.color.withValues(alpha: 0.55)
          : AppColors.surfaceContainerHighest,
      borderColor: equipped ? item.color : AppColors.outlineVariant,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Önizleme: yalnızca bu aksesuarı takmış küçük tilki.
          Expanded(
            child: Opacity(
              opacity: locked ? 0.45 : 1,
              child: Center(child: FoxAvatar(size: 92, items: [item])),
            ),
          ),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.labelLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 6),
          _TileBadge(item: item, owned: owned, equipped: equipped),
        ],
      ),
    );
  }
}

/// Kutunun altındaki durum etiketi: fiyat, "TAK" ya da "TAKILI".
class _TileBadge extends StatelessWidget {
  const _TileBadge({
    required this.item,
    required this.owned,
    required this.equipped,
  });

  final FoxItem item;
  final bool owned;
  final bool equipped;

  @override
  Widget build(BuildContext context) {
    if (equipped) {
      return _pill(
        color: item.color,
        textColor: Colors.white,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'TAKILI',
              style: AppText.labelSm.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (owned) {
      return _pill(
        color: AppColors.surfaceContainerHigh,
        textColor: AppColors.primary,
        child: Text(
          'TAK',
          style: AppText.labelSm.copyWith(color: AppColors.primary),
        ),
      );
    }

    return _pill(
      color: AppColors.sunnyYellow.withValues(alpha: 0.28),
      textColor: AppColors.onSurface,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFE9A800)),
          const SizedBox(width: 3),
          Text('${item.price}', style: AppText.labelSm),
        ],
      ),
    );
  }

  Widget _pill({
    required Color color,
    required Color textColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Satın alma onayı
// ---------------------------------------------------------------------------

class _BuyDialog extends StatelessWidget {
  const _BuyDialog({required this.item, required this.balance});

  final FoxItem item;
  final int balance;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: DepthBox(
        color: AppColors.creamBg,
        depthColor: AppColors.surfaceContainerHighest,
        borderColor: AppColors.sunnyYellow,
        radius: AppRadius.lg,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FoxAvatar(size: 130, items: [item]),
            const SizedBox(height: 6),
            Text(
              item.name,
              style: AppText.headlineMd.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Bu aksesuar ${item.price} yıldız.',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            Text(
              'Alınca ${balance - item.price} yıldızın kalır.',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Squishy(
              key: const ValueKey('buy_confirm'),
              onTap: () => Navigator.of(context).pop(true),
              color: AppColors.foxOrange,
              depthColor: AppColors.primary,
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Center(
                child: Text(
                  'ALALIM!',
                  style: AppText.labelLg.copyWith(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              key: const ValueKey('buy_cancel'),
              onTap: () => Navigator.of(context).pop(false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Şimdi değil',
                  style: AppText.labelLg.copyWith(color: AppColors.secondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
