import 'package:flutter/material.dart';

import '../cards/card_collection.dart';
import '../games/game_summary.dart';
import '../profile/player_profile.dart';
import '../theme/app_theme.dart';

/// Rozet ilerlemesinin okunduğu kaynaklar.
class BadgeContext {
  const BadgeContext({required this.profile, required this.collection});

  final PlayerProfile profile;
  final CardCollection collection;
}

/// Rozet grupları — sayfadaki filtre çipleri bu sırayı kullanır.
enum BadgeGroup {
  oyun('Oyun', AppColors.foxOrange),
  koleksiyon('Koleksiyon', AppColors.bandanaTeal),
  stil('Stil', AppColors.berryPink);

  const BadgeGroup(this.label, this.accent);

  final String label;
  final Color accent;
}

/// Tek bir rozetin tanımı.
///
/// [progressOf] her zaman güncel duruma bakar; kazanılmışlık ayrıca
/// saklanmaz, böylece kayıt ile ekran hiç ayrışmaz.
class BadgeDef {
  const BadgeDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.group,
    required this.progressOf,
    this.target = 0,
    this.targetOf,
  });

  /// Kalıcı kimlik — "yeni rozet" işareti bu değerle saklanır.
  final String id;
  final String title;

  /// Nasıl kazanıldığını anlatan tek cümle.
  final String description;
  final IconData icon;
  final BadgeGroup group;

  /// Rozetin açılması için gereken sabit değer.
  final int target;

  /// Hedef duruma göre değişiyorsa (ör. deste uzunluğu) bu kullanılır.
  final int Function(BadgeContext context)? targetOf;

  final int Function(BadgeContext context) progressOf;

  Color get accent => group.accent;

  int resolveTarget(BadgeContext context) => targetOf?.call(context) ?? target;
}

/// Bir rozetin o anki durumu.
class BadgeStatus {
  const BadgeStatus({
    required this.def,
    required this.progress,
    required this.target,
  });

  final BadgeDef def;

  /// Rozetin o anki ilerlemesi.
  final int progress;

  /// Bu rozetin hedefi.
  final int target;

  bool get earned => progress >= target;

  /// 0–1 arası ilerleme oranı.
  double get ratio =>
      target == 0 ? 1 : (progress / target).clamp(0.0, 1.0).toDouble();
}

/// Tüm rozetler; kolaydan zora doğru sıralı.
final badgeCatalog = <BadgeDef>[
  BadgeDef(
    id: 'first_game',
    title: 'İlk Adım',
    description: 'İlk oyununu tamamla.',
    icon: Icons.flag_rounded,
    group: BadgeGroup.oyun,
    target: 1,
    progressOf: (context) => context.profile.gamesPlayed,
  ),
  BadgeDef(
    id: 'ten_games',
    title: 'Oyun Dostu',
    description: '10 oyun tamamla.',
    icon: Icons.sports_esports_rounded,
    group: BadgeGroup.oyun,
    target: 10,
    progressOf: (context) => context.profile.gamesPlayed,
  ),
  BadgeDef(
    id: 'fifty_games',
    title: 'Oyun Kurdu',
    description: '50 oyun tamamla.',
    icon: Icons.local_fire_department_rounded,
    group: BadgeGroup.oyun,
    target: 50,
    progressOf: (context) => context.profile.gamesPlayed,
  ),
  BadgeDef(
    id: 'all_games',
    title: 'Her Oyundan Tat',
    description: 'Her oyunun en az üçer turunu oyna.',
    icon: Icons.grid_view_rounded,
    group: BadgeGroup.oyun,
    target: GameKind.values.length,
    progressOf: (context) => context.profile.gamesPlayedAtLeast(3),
  ),
  BadgeDef(
    id: 'sudoku_fan',
    title: 'Sudoku Çırağı',
    description: '10 Sudoku bulmacası bitir.',
    icon: Icons.grid_on_rounded,
    group: BadgeGroup.oyun,
    target: 10,
    progressOf: (context) => context.profile.recordOf(GameKind.sudoku).plays,
  ),
  BadgeDef(
    id: 'tetris_pro',
    title: 'Tetris Ustası',
    description: 'Tek Tetris turunda 1000 puan yap.',
    icon: Icons.view_quilt_rounded,
    group: BadgeGroup.oyun,
    target: 1000,
    progressOf: (context) =>
        context.profile.recordOf(GameKind.tetris).bestScore,
  ),
  BadgeDef(
    id: 'blok_pro',
    title: 'Blok Ustası',
    description: 'Tek Blok Patlat turunda 2000 puan yap.',
    icon: Icons.apps_rounded,
    group: BadgeGroup.oyun,
    target: 2000,
    progressOf: (context) => context.profile.recordOf(GameKind.blok).bestScore,
  ),
  BadgeDef(
    id: 'first_card',
    title: 'Meraklı Tilki',
    description: 'İlk bilgi kartını topla.',
    icon: Icons.auto_stories_rounded,
    group: BadgeGroup.koleksiyon,
    target: 1,
    progressOf: (context) => context.collection.collectedCount,
  ),
  BadgeDef(
    id: 'ten_cards',
    title: 'Koleksiyoncu',
    description: '10 bilgi kartı topla.',
    icon: Icons.photo_library_rounded,
    group: BadgeGroup.koleksiyon,
    target: 10,
    progressOf: (context) => context.collection.collectedCount,
  ),
  BadgeDef(
    id: 'all_cards',
    title: 'Albüm Kahramanı',
    description: 'Albümdeki bütün kartları tamamla.',
    icon: Icons.workspace_premium_rounded,
    group: BadgeGroup.koleksiyon,
    // Hedef deste uzunluğu; kart eklendikçe rozet de büyür.
    targetOf: (context) => context.collection.total,
    progressOf: (context) => context.collection.collectedCount,
  ),
  BadgeDef(
    id: 'stars_50',
    title: 'Yıldız Toplayıcı',
    description: 'Toplam 50 yıldız kazan.',
    icon: Icons.star_rounded,
    group: BadgeGroup.koleksiyon,
    target: 50,
    progressOf: (context) => context.profile.totalStarsEarned,
  ),
  BadgeDef(
    id: 'stars_250',
    title: 'Yıldız Ustası',
    description: 'Toplam 250 yıldız kazan.',
    icon: Icons.auto_awesome_rounded,
    group: BadgeGroup.koleksiyon,
    target: 250,
    progressOf: (context) => context.profile.totalStarsEarned,
  ),
  BadgeDef(
    id: 'first_item',
    title: 'Şık Tilki',
    description: 'Atölyeden ilk aksesuarını al.',
    icon: Icons.checkroom_rounded,
    group: BadgeGroup.stil,
    target: 1,
    progressOf: (context) => context.profile.ownedCount,
  ),
  BadgeDef(
    id: 'five_items',
    title: 'Moda İkonu',
    description: '5 farklı aksesuar topla.',
    icon: Icons.diamond_rounded,
    group: BadgeGroup.stil,
    target: 5,
    progressOf: (context) => context.profile.ownedCount,
  ),
];

/// Tüm rozetleri güncel duruma göre değerlendirir.
List<BadgeStatus> evaluateBadges(BadgeContext context) => [
  for (final def in badgeCatalog)
    BadgeStatus(
      def: def,
      progress: def.progressOf(context),
      target: def.resolveTarget(context),
    ),
];

/// Kazanılmış rozetler.
List<BadgeStatus> earnedBadges(BadgeContext context) =>
    evaluateBadges(context).where((status) => status.earned).toList();
