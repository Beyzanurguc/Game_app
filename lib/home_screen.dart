import 'package:flutter/material.dart';
import 'package:game_app/games/yapboz/yapboz_screen.dart';

import 'badges/badge_catalog.dart';
import 'badges/badge_unlocked_dialog.dart';
import 'badges/badges_screen.dart';
import 'cards/album_screen.dart';
import 'cards/card_collection.dart';
import 'games/blok/blok_screen.dart';
import 'games/sudoku/sudoku_difficulty_sheet.dart';
import 'games/sudoku/sudoku_screen.dart';
import 'games/tetris/tetris_screen.dart';
import 'profile/fox_avatar.dart';
import 'profile/fox_items.dart';
import 'profile/fox_workshop_screen.dart';
import 'profile/player_profile.dart';
import 'settings/app_settings.dart';
import 'settings/daily_limit_dialog.dart';
import 'settings/settings_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/squishy.dart';
import 'games/quiz/quiz_screen.dart';

/// Ana sayfa: selamlama, bilgi kartı albümü ilerlemesi, oyun listesi ve
/// alt gezinme çubuğu.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  /// Sayfa açıldığında elde olan rozetler.
  ///
  /// Kutlama yalnızca bundan sonra kazanılanlar için yapılır; uygulamayı her
  /// açışta eski rozetler için pencere açılmaz.
  Set<String>? _knownBadges;

  /// Kutlama penceresi ekrandayken ikinci bir tanesi açılmaz.
  bool _celebrating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Kart kaydetmek, yıldız kazanmak gibi değişiklikler rozet açabilir.
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrateNewBadges());
  }

  /// Yeni kazanılan rozetleri sırayla kutlar.
  Future<void> _celebrateNewBadges() async {
    if (!mounted || _celebrating) return;

    final earned = earnedBadges(
      BadgeContext(
        profile: PlayerProfileScope.of(context),
        collection: CardCollectionScope.of(context),
      ),
    );

    final known = _knownBadges;
    if (known == null) {
      // İlk ölçüm: sayfa açılırken elde olanlar kutlanmaz.
      _knownBadges = {for (final status in earned) status.def.id};
      return;
    }

    final fresh = [
      for (final status in earned)
        if (!known.contains(status.def.id)) status,
    ];
    if (fresh.isEmpty) return;

    // Oyun ekranı üstteyken kutlama yapılmaz; ana sayfaya dönünce gösterilir.
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

    _knownBadges = {...known, for (final status in fresh) status.def.id};
    _celebrating = true;
    for (final status in fresh) {
      if (!mounted) break;
      await showBadgeUnlockedDialog(context, status);
    }
    _celebrating = false;
  }

  static const _games = <_GameInfo>[
    _GameInfo(
      id: GameId.tetris,
      title: 'Tetris',
      subtitle: 'Şekilleri yerleştir',
      badge: 'Bulmaca',
      icon: Icons.view_quilt_rounded,
      accent: AppColors.berryPink,
      tint: Color(0xFFFFE9EE),
    ),
    _GameInfo(
      id: GameId.sudoku,
      title: 'Sudoku',
      subtitle: 'Sayıları tamamla',
      badge: 'Bulmaca',
      icon: Icons.grid_on_rounded,
      accent: AppColors.bandanaTeal,
      tint: Color(0xFFE4F3F2),
    ),
    _GameInfo(
      id: GameId.blokPatlat,
      title: 'Blok Patlat',
      subtitle: 'Satır ve sütun patlat',
      badge: 'Bulmaca',
      icon: Icons.apps_rounded,
      accent: AppColors.tertiaryContainer,
      tint: Color(0xFFE2F4FC),
    ),
    _GameInfo(
      id: GameId.quiz,
      title: 'Quiz',
      subtitle: 'Soruları cevapla',
      badge: 'Bulmaca',
      icon: Icons.question_answer_rounded,
      accent: AppColors.sunnyYellow,
      tint: Color(0xFFFCF5DF),
    ),
    _GameInfo(
      id: GameId.yapboz,
      title: 'Yapboz',
      subtitle: 'Parçaları birleştir',
      badge: 'Bulmaca',
      icon: Icons.extension_rounded,
      accent: AppColors.leafGreen,
      tint: Color(0xFFE8F5E9),
    ),
  ];

  Future<void> _openGame(_GameInfo game) async {
    final int? earnedStars;

    switch (game.id) {
      case GameId.sudoku:
        // Sudoku'da oyun başlamadan önce zorluk seçilir.
        final difficulty = await showSudokuDifficultySheet(context);
        if (difficulty == null || !mounted) return;
        // Zorluk seçilmeden hak düşmez.
        if (!await ensurePlayAllowed(context) || !mounted) return;

        earnedStars = await Navigator.of(context).push<int>(
          MaterialPageRoute(
            builder: (context) => SudokuScreen(difficulty: difficulty),
          ),
        );
      case GameId.tetris:
        if (!await ensurePlayAllowed(context) || !mounted) return;

        earnedStars = await Navigator.of(context).push<int>(
          MaterialPageRoute(builder: (context) => const TetrisScreen()),
        );
      case GameId.blokPatlat:
        if (!await ensurePlayAllowed(context) || !mounted) return;

        earnedStars = await Navigator.of(context).push<int>(
          MaterialPageRoute(builder: (context) => const BlokScreen()),
        );
      case GameId.quiz:
        if (!await ensurePlayAllowed(context) || !mounted) return;

        earnedStars = await Navigator.of(context).push<int>(
          MaterialPageRoute(builder: (context) => const QuizScreen()),
        );
      case GameId.yapboz:
        if (!await ensurePlayAllowed(context) || !mounted) return;

        earnedStars = await Navigator.of(context).push<int>(
          MaterialPageRoute(builder: (context) => const YapbozScreen()),
        );
    }
    if (!mounted) return;

    // Kartın albüme eklenmesi ödül ekranında yapılıyor; burada yıldız eklenir.
    if (earnedStars != null) {
      CardCollectionScope.of(context).addStars(earnedStars);
    }
    // Yıldızsız çıkılsa bile oyun sayısı rozet açmış olabilir.
    await _celebrateNewBadges();
  }

  void _openAlbum() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AlbumScreen()));
  }

  void _openBadges() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const BadgesScreen()));
  }

  Future<void> _openWorkshop() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const FoxWorkshopScreen()));
    // Atölyeden alınan aksesuar stil rozetlerini açabilir.
    await _celebrateNewBadges();
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  /// Alt çubuk bir başlatıcı gibi çalışır: ilk sekme bu sayfa, diğerleri
  /// üstüne açılıp geri dönülen sayfalar. Bu yüzden seçili sekme değişmez.
  void _onNavTap(int index) {
    switch (index) {
      case 1:
        _openAlbum();
      case 2:
        _openBadges();
      case 3:
        _openSettings();
      default:
        setState(() => _navIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collection = CardCollectionScope.of(context);
    final profile = PlayerProfileScope.of(context);
    final settings = AppSettingsScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            final horizontal = isWide
                ? AppSpacing.marginDesktop
                : AppSpacing.marginMobile;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 32),
                  children: [
                    _GreetingBar(
                      name: settings.childName,
                      stars: collection.stars,
                      items: profile.equippedItems,
                      onAvatarTap: _openWorkshop,
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    _DailyGamesCard(
                      playsToday: settings.playsToday,
                      dailyLimit: settings.dailyGameLimit,
                    ),
                    const SizedBox(height: AppSpacing.base * 1.5),
                    _AlbumProgressCard(
                      collected: collection.collectedCount,
                      total: collection.total,
                      onTap: _openAlbum,
                    ),
                    const SizedBox(height: AppSpacing.gutter + 4),
                    const _SectionHeader(
                      title: 'Oyunlar',
                      hint: 'Her oyundan sonra yeni bir bilgi kartı!',
                    ),
                    const SizedBox(height: AppSpacing.base * 2),
                    if (isWide)
                      // Geniş ekranda kartlar iki sütuna akar; yükseklik
                      // içeriğe göre belirlenir, sabit oran yok.
                      LayoutBuilder(
                        builder: (context, inner) {
                          final cardWidth =
                              (inner.maxWidth - AppSpacing.gutter) / 2;
                          return Wrap(
                            spacing: AppSpacing.gutter,
                            runSpacing: AppSpacing.gutter,
                            children: [
                              for (final game in _games)
                                SizedBox(
                                  width: cardWidth,
                                  child: _GameTile(
                                    game: game,
                                    onTap: () => _openGame(game),
                                  ),
                                ),
                              SizedBox(
                                width: cardWidth,
                                child: const _ComingSoonTile(),
                              ),
                            ],
                          );
                        },
                      )
                    else ...[
                      for (final game in _games) ...[
                        _GameTile(game: game, onTap: () => _openGame(game)),
                        const SizedBox(height: AppSpacing.base * 2),
                      ],
                      const _ComingSoonTile(),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _FoxBottomNav(
        currentIndex: _navIndex,
        onChanged: _onNavTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selamlama
// ---------------------------------------------------------------------------

class _GreetingBar extends StatelessWidget {
  const _GreetingBar({
    required this.name,
    required this.stars,
    required this.items,
    required this.onAvatarTap,
  });

  final String name;
  final int stars;

  /// Tilkinin takılı aksesuarları.
  final List<FoxItem> items;

  /// Avatara dokunmak atölyeyi açar.
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          key: const ValueKey('home_avatar'),
          onTap: onAvatarTap,
          child: Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.foxOrange, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: FoxAvatar(size: 52, items: items),
          ),
        ),
        const SizedBox(width: AppSpacing.base * 1.5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // Ad isteğe bağlı; boş bırakıldıysa adsız selamlanır.
                name.isEmpty ? 'Merhaba!' : 'Merhaba, $name!',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.titleMd,
              ),
              const SizedBox(height: 2),
              Text(
                'Bugün ne oynayalım?',
                style: AppText.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        _StarPill(stars: stars),
      ],
    );
  }
}

class _StarPill extends StatelessWidget {
  const _StarPill({required this.stars});

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
          Text('$stars', style: AppText.labelLg),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bilgi kartı albümü ilerlemesi
// ---------------------------------------------------------------------------

/// Bugünün oyun hakkı.
///
/// Çubuk ebeveynin belirlediği **günlük oyun limitine** göre dolar: her
/// oynanan oyunla biraz daha ilerler, limit dolunca tamamlanır.
class _DailyGamesCard extends StatelessWidget {
  const _DailyGamesCard({required this.playsToday, required this.dailyLimit});

  /// Bugün başlanan oyun sayısı.
  final int playsToday;

  /// Ebeveynin belirlediği günlük oyun limiti.
  final int dailyLimit;

  @override
  Widget build(BuildContext context) {
    final ratio = dailyLimit == 0
        ? 0.0
        : (playsToday / dailyLimit).clamp(0.0, 1.0);
    final full = playsToday >= dailyLimit;

    return DepthBox(
      key: const ValueKey('home_daily_games'),
      color: AppColors.primaryFixed,
      depthColor: AppColors.foxOrange.withValues(alpha: 0.45),
      borderColor: AppColors.foxOrange,
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sports_esports_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Bugünün oyunları',
                style: AppText.labelLg.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressTrack(ratio: ratio.toDouble()),
          const SizedBox(height: 10),
          // Sayılar büyüdükçe satır uzuyor; dar telefonlarda kırılıp kartı
          // büyütmesin diye gerekirse küçültülür.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              full
                  ? 'Bugünlük oyunlar tamam!'
                  : 'Bugün $playsToday / $dailyLimit oyun oynadın',
              maxLines: 1,
              softWrap: false,
              style: AppText.bodyMd.copyWith(
                color: AppColors.onPrimaryFixedVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Albümde toplanan kartların ilerlemesi.
class _AlbumProgressCard extends StatelessWidget {
  const _AlbumProgressCard({
    required this.collected,
    required this.total,
    required this.onTap,
  });

  final int collected;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (collected / total).clamp(0.0, 1.0);

    return Squishy(
      key: const ValueKey('home_album'),
      onTap: onTap,
      color: AppColors.secondaryContainer,
      depthColor: const Color(0xFF8FC9C8),
      borderColor: AppColors.bandanaTeal,
      radius: AppRadius.lg,
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Bilgi albümüm',
                      style: AppText.labelLg.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _AlbumTrack(ratio: ratio.toDouble()),
                const SizedBox(height: 10),
                // Deste büyüdükçe sayı da uzuyor; dar telefonlarda satır
                // kırılıp kartı büyütmesin diye gerekirse küçültülür.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$collected / $total kart toplandı',
                    maxLines: 1,
                    softWrap: false,
                    style: AppText.bodyMd.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Mascot(size: 84),
        ],
      ),
    );
  }
}

/// Albüm kartının ince ilerleme çubuğu.
///
/// Günlük kartın çubuğundan farkı: ucunda maskot yok, çünkü maskot kartın
/// sağında zaten duruyor.
class _AlbumTrack extends StatelessWidget {
  const _AlbumTrack({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: 14, color: Colors.white.withValues(alpha: 0.75)),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            widthFactor: ratio,
            child: Container(
              height: 14,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.bandanaTeal, AppColors.secondary],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kalın, hap biçimli ilerleme çubuğu; ucunda maskot rozeti taşır.
class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    const height = 18.0;
    const knob = 26.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fill = (width * ratio).clamp(knob, width);

        return SizedBox(
          height: knob,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: height,
                width: fill,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.sunnyYellow, AppColors.foxOrange],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                left: fill - knob,
                child: Container(
                  height: knob,
                  width: knob,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.foxOrange, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: const Mascot(size: knob),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bölüm başlığı ve oyun kartları
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.headlineLg.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 2),
        Text(
          hint,
          style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// Ana sayfadaki oyun kimlikleri.
enum GameId { tetris, sudoku, blokPatlat, quiz, yapboz }

class _GameInfo {
  const _GameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  final GameId id;
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accent;

  /// Kart zemini için accent renginin çok açık tonu.
  final Color tint;

  /// Alt kenarlık (derinlik) rengi — accent'in koyu tonu.
  Color get depth => _shade(0.16);

  /// Başlık metni rengi — okunabilirlik için daha da koyu.
  Color get ink => _shade(0.26);

  Color _shade(double amount) {
    final hsl = HSLColor.fromColor(accent);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game, required this.onTap});

  final _GameInfo game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squishy(
      onTap: onTap,
      color: game.tint,
      depthColor: game.depth.withValues(alpha: 0.45),
      borderColor: game.accent.withValues(alpha: 0.55),
      radius: AppRadius.lg,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          DepthBox(
            color: game.accent,
            depthColor: game.depth,
            radius: AppRadius.md,
            depth: 4,
            child: SizedBox(
              height: 56,
              width: 60,
              child: Icon(game.icon, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  game.title,
                  style: AppText.headlineMd.copyWith(color: game.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  game.subtitle,
                  style: AppText.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    game.badge,
                    style: AppText.labelSm.copyWith(color: game.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: AppSpacing.touchTarget,
            width: AppSpacing.touchTarget,
            decoration: const BoxDecoration(
              color: AppColors.foxOrange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33F47D31),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const DashedBorderPainter(color: AppColors.outlineVariant),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              alignment: Alignment.center,
              child: Text(
                '?',
                style: AppText.headlineMd.copyWith(color: AppColors.outline),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Yakında',
                    style: AppText.titleMd.copyWith(color: AppColors.outline),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Yeni oyunlar ekleniyor',
                    style: AppText.bodyMd.copyWith(
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
// Alt gezinme
// ---------------------------------------------------------------------------

class _FoxBottomNav extends StatelessWidget {
  const _FoxBottomNav({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _items = <(IconData, String)>[
    (Icons.sports_esports_rounded, 'Oyunlar'),
    (Icons.photo_library_rounded, 'Albüm'),
    (Icons.military_tech_rounded, 'Rozetler'),
    (Icons.settings_rounded, 'Ayarlar'),
  ];

  @override
  Widget build(BuildContext context) {
    // Üstteki 4px'lik şerit, tasarımdaki kalın kenarlığı taklit eder.
    return ColoredBox(
      color: AppColors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _items[i].$1,
                        label: _items[i].$2,
                        selected: i == currentIndex,
                        onTap: () => onChanged(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.foxOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.labelSm.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
