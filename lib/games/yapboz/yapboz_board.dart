import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'puzzle_catalog.dart';
import 'yapboz_setup.dart';

/// Resmin tek bir parçası.
///
/// Resmin tamamı [FittedBox] ile parça boyutunun `size` katına büyütülüp
/// istenen hücreye kaydırılır; böylece her parça, bütün resmin kendi payına
/// düşen bölümünü gösterir. Resim kare değilse [BoxFit.cover] ortadan kırpar.
class PuzzlePieceImage extends StatelessWidget {
  const PuzzlePieceImage({
    super.key,
    required this.picture,
    required this.pieceId,
    required this.size,
    required this.extent,
  });

  final PuzzlePicture picture;

  /// Parçanın resimdeki sırası (0 = sol üst, soldan sağa okunur).
  final int pieceId;

  /// Izgaranın bir kenarındaki parça sayısı.
  final int size;

  /// Parçanın ekrandaki kenar uzunluğu.
  final double extent;

  @override
  Widget build(BuildContext context) {
    final row = pieceId ~/ size;
    final col = pieceId % size;
    final full = extent * size;

    return SizedBox(
      height: extent,
      width: extent,
      child: ClipRect(
        child: OverflowBox(
          maxHeight: full,
          maxWidth: full,
          minHeight: full,
          minWidth: full,
          alignment: Alignment.topLeft,
          child: Transform.translate(
            offset: Offset(-col * extent, -row * extent),
            child: SizedBox(
              height: full,
              width: full,
              child: PuzzleImage(picture: picture),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tahtadaki boş yuva — parçanın nereye geleceğini gösterir.
class PuzzleSlotFrame extends StatelessWidget {
  const PuzzleSlotFrame({
    super.key,
    required this.highlighted,
    required this.accent,
  });

  /// Sürüklenen parça bu yuvanın üzerinde mi?
  final bool highlighted;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: highlighted
            ? accent.withValues(alpha: 0.25)
            : AppColors.surfaceContainer.withValues(alpha: 0.6),
        border: Border.all(
          color: highlighted ? accent : AppColors.outlineVariant,
          width: highlighted ? 3 : 1,
        ),
      ),
    );
  }
}
