import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/squishy.dart';
import 'badge_catalog.dart';
import 'badges_screen.dart';

/// Yeni kazanılan rozeti havai fişeklerle kutlar.
///
/// Kutlama kapatılana kadar bekler; birden çok rozet aynı anda kazanıldıysa
/// çağıran taraf bunları sırayla gösterir.
Future<void> showBadgeUnlockedDialog(BuildContext context, BadgeStatus status) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _BadgeUnlockedDialog(status: status),
  );
}

class _BadgeUnlockedDialog extends StatelessWidget {
  const _BadgeUnlockedDialog({required this.status});

  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: ValueKey('badge_unlocked_${status.def.id}'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.gutter),
      child: DepthBox(
        color: AppColors.creamBg,
        depthColor: AppColors.surfaceContainerHighest,
        borderColor: AppColors.sunnyYellow,
        radius: AppRadius.lg,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Yeni rozet kazandın!',
              textAlign: TextAlign.center,
              style: AppText.headlineMd.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            FireworkBurst(
              color: status.def.accent,
              child: BadgeMedal(status: status, size: 96),
            ),
            const SizedBox(height: 4),
            Text(
              status.def.title,
              textAlign: TextAlign.center,
              style: AppText.titleMd.copyWith(color: status.def.accent),
            ),
            const SizedBox(height: 4),
            Text(
              status.def.description,
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            Squishy(
              key: const ValueKey('badge_unlocked_ok'),
              onTap: () => Navigator.of(context).pop(),
              color: AppColors.foxOrange,
              depthColor: AppColors.primary,
              radius: AppRadius.md,
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Center(
                child: Text(
                  'HARİKA!',
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

/// Çocuğun çevresinde bir kez patlayan havai fişek efekti.
///
/// Bilerek tek seferlik: ekranda sonsuz dönen bir animasyon bırakmaz.
class FireworkBurst extends StatefulWidget {
  const FireworkBurst({
    super.key,
    required this.color,
    required this.child,
    this.padding = 26,
  });

  /// Parçacıklara eşlik eden ana renk (rozetin kendi rengi).
  final Color color;

  /// Çevresinde patlama olacak öğe.
  final Widget child;

  /// Parçacıkların dağılacağı boşluk.
  final double padding;

  @override
  State<FireworkBurst> createState() => _FireworkBurstState();
}

class _FireworkBurstState extends State<FireworkBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Rozet patlamayla birlikte yerine oturur.
        final pop = Curves.easeOutBack.transform(
          (_controller.value * 3).clamp(0.0, 1.0),
        );
        return CustomPaint(
          painter: _FireworkPainter(
            progress: _controller.value,
            color: widget.color,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.padding),
            child: Transform.scale(scale: 0.5 + 0.5 * pop, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Merkezden dışa saçılan, sönerek kaybolan parçacıklar.
class _FireworkPainter extends CustomPainter {
  const _FireworkPainter({required this.progress, required this.color});

  /// 0–1 arası animasyon ilerlemesi.
  final double progress;

  /// Rozetin kendi rengi; şenlik için ona başka renkler eşlik eder.
  final Color color;

  static const _bursts = 4;
  static const _perBurst = 9;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final reach = size.shortestSide * 0.56;
    final palette = [
      color,
      AppColors.sunnyYellow,
      AppColors.berryPink,
      AppColors.tertiaryContainer,
    ];
    final paint = Paint()..style = PaintingStyle.fill;

    for (var burst = 0; burst < _bursts; burst++) {
      // Patlamalar sırayla tetiklenir; sonuncusu animasyonun sonuna denk gelir.
      final start = burst * 0.18;
      final local = ((progress - start) / (1 - start)).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;

      final spread = Curves.easeOutCubic.transform(local);
      final fade = 1 - local;
      final tilt = burst * (math.pi / _perBurst) * 0.8;

      for (var i = 0; i < _perBurst; i++) {
        final angle = (i / _perBurst) * 2 * math.pi + tilt;
        // Parçacıklar eşit uzağa gitmesin; patlama daha canlı görünür.
        final radius = reach * spread * (0.7 + 0.3 * ((i + burst) % 3) / 2);
        final offset =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        paint.color = palette[(i + burst) % palette.length].withValues(
          alpha: fade,
        );
        canvas.drawCircle(offset, 1 + reach * 0.055 * fade, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FireworkPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
