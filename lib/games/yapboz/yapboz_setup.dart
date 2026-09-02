import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/squishy.dart';
import 'puzzle_catalog.dart';
import 'yapboz_engine.dart';

/// Kurulum ekranının sonucu: hangi resim, hangi zorluk.
typedef YapbozSetup = ({PuzzlePicture picture, YapbozDifficulty difficulty});

/// Oyuna başlamadan önce resim ve zorluk seçtiren adım.
///
/// Ayrı bir sayfa yerine [YapbozScreen] içinde bir aşama olarak gösterilir;
/// böylece oyun içinden "başka resim" demek de aynı görünümü açar.
class YapbozSetupView extends StatefulWidget {
  const YapbozSetupView({
    super.key,
    required this.pictures,
    required this.onStart,
    required this.onBack,
    this.initial,
  });

  /// Seçilebilecek resimler; Firestore'dan gelir ve boş olabilir.
  final List<PuzzlePicture> pictures;

  /// Seçim tamamlandığında çağrılır.
  final void Function(YapbozSetup setup) onStart;

  /// Geri okuna basıldığında çağrılır.
  final VoidCallback onBack;

  /// Oyun içinden gelindiğinde önceki seçim işaretli gelsin.
  final YapbozSetup? initial;

  @override
  State<YapbozSetupView> createState() => _YapbozSetupViewState();
}

class _YapbozSetupViewState extends State<YapbozSetupView> {
  late PuzzlePicture _picture =
      widget.initial?.picture ?? widget.pictures.first;
  late YapbozDifficulty _difficulty =
      widget.initial?.difficulty ?? YapbozDifficulty.kolay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Başlık ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                key: const ValueKey('yapboz_setup_back'),
                onTap: widget.onBack,
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
              Expanded(
                child: Text(
                  'Yapboz',
                  textAlign: TextAlign.center,
                  style: AppText.headlineMd.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.touchTarget),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            key: const ValueKey('yapboz_setup_list'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.base * 2,
              AppSpacing.marginMobile,
              AppSpacing.gutter,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hangi resmi yapalım?',
                          style: AppText.headlineMd.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bir resim ve zorluk seç, sonra parçaları yerine sürükle.',
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
              const SizedBox(height: AppSpacing.base * 2),

              // ── Resim seçimi ──
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.86,
                    ),
                itemCount: widget.pictures.length,
                itemBuilder: (context, index) {
                  final picture = widget.pictures[index];
                  return _PictureTile(
                    picture: picture,
                    selected: picture.id == _picture.id,
                    onTap: () => setState(() => _picture = picture),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.base * 3),

              Text(
                'Zorluk',
                style: AppText.headlineMd.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.base * 1.5),
              for (final difficulty in YapbozDifficulty.values) ...[
                _DifficultyTile(
                  difficulty: difficulty,
                  selected: difficulty == _difficulty,
                  onTap: () => setState(() => _difficulty = difficulty),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),

        // ── Başla ──
        Container(
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
                key: const ValueKey('yapboz_start'),
                onTap: () => widget.onStart(
                  (picture: _picture, difficulty: _difficulty),
                ),
                color: AppColors.foxOrange,
                depthColor: AppColors.primary,
                radius: AppRadius.md,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'BAŞLA',
                    style: AppText.labelLg.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Resim kutusu
// =============================================================================

class _PictureTile extends StatelessWidget {
  const _PictureTile({
    required this.picture,
    required this.selected,
    required this.onTap,
  });

  final PuzzlePicture picture;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squishy(
      onTap: onTap,
      color: AppColors.creamBg,
      depthColor: selected
          ? AppColors.primary
          : AppColors.surfaceContainerHighest,
      borderColor: selected ? AppColors.foxOrange : AppColors.outlineVariant,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: PuzzleImage(picture: picture),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(picture.icon, size: 15, color: picture.accent),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  picture.title,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.labelLg.copyWith(color: AppColors.onSurface),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: AppColors.foxOrange,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Yapboz resmi.
///
/// Görsel Firestore belgesinden bayt olarak geliyor. Aynı yapbozun bütün
/// parçaları [PuzzlePicture.imageBytes] örneğini paylaştığı için Flutter'ın
/// görsel önbelleği JPEG'i bir kez çözer; 25 parçalık tahtada bile tek çözme
/// yapılır. Görsel yoksa oyun çökmez, yer tutucu çizilir.
class PuzzleImage extends StatelessWidget {
  const PuzzleImage({super.key, required this.picture, this.fit = BoxFit.cover});

  final PuzzlePicture picture;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final bytes = picture.imageBytes;
    if (bytes == null || bytes.isEmpty) return _placeholder();

    return Image.memory(
      bytes,
      fit: fit,
      // Parça parça çizildiği için her karede yeniden canlandırma olmasın.
      gaplessPlayback: true,
      errorBuilder: (context, error, stack) => _placeholder(),
    );
  }

  Widget _placeholder() => ColoredBox(
    color: picture.accent.withValues(alpha: 0.25),
    child: Center(
      child: Icon(picture.icon, color: picture.accent, size: 32),
    ),
  );
}

// =============================================================================
// Zorluk kutusu
// =============================================================================

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final YapbozDifficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Squishy(
      onTap: onTap,
      color: selected ? AppColors.primaryFixed : AppColors.creamBg,
      depthColor: selected
          ? AppColors.foxOrange
          : AppColors.surfaceContainerHighest,
      borderColor: selected ? AppColors.foxOrange : AppColors.outlineVariant,
      radius: AppRadius.md,
      depth: 5,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          // Izgara önizlemesi — zorluk göz kararı anlaşılsın.
          SizedBox(
            height: 34,
            width: 34,
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: difficulty.size,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              children: [
                for (var i = 0; i < difficulty.size * difficulty.size; i++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.foxOrange
                          : AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  difficulty.label,
                  style: AppText.labelLg.copyWith(color: AppColors.onSurface),
                ),
                Text(
                  difficulty.pieceLabel,
                  style: AppText.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.foxOrange,
              size: 24,
            ),
        ],
      ),
    );
  }
}
