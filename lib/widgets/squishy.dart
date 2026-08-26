import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kalın alt katmanla derinlik veren kutu.
///
/// Flutter yuvarlatılmış köşelerde tek taraflı kenarlığa izin vermediği için
/// derinlik, arkaya konan koyu bir "dilim" ile üretilir.
class DepthBox extends StatelessWidget {
  const DepthBox({
    super.key,
    required this.child,
    required this.color,
    required this.depthColor,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.depth = 6,
    this.depthVisible = true,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;

  /// Arkadaki koyu dilimin rengi.
  final Color depthColor;
  final Color? borderColor;
  final double radius;
  final double depth;

  /// Basılı durumda dilim gizlenir; öğe aşağı inmiş gibi görünür.
  final bool depthVisible;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(color: depthColor, borderRadius: borderRadius),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: depthVisible ? depth : 0),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!, width: 2),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Basıldığında alt dilimi "kaybolup" aşağı inen dokunsal yüzey.
///
/// DESIGN.md'deki fiziksel metaforu uygular: gölge yerine kalın alt katman,
/// basılı durumda 4–6px aşağı kayma. Dış ölçü sabit kalır.
class Squishy extends StatefulWidget {
  const Squishy({
    super.key,
    required this.child,
    required this.color,
    required this.depthColor,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.depth = 6,
    this.onTap,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final Color depthColor;
  final Color? borderColor;
  final double radius;
  final double depth;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  State<Squishy> createState() => _SquishyState();
}

class _SquishyState extends State<Squishy> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: widget.onTap,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(top: _pressed ? widget.depth : 0),
        child: DepthBox(
          color: widget.color,
          depthColor: widget.depthColor,
          borderColor: widget.borderColor,
          radius: widget.radius,
          depth: widget.depth,
          depthVisible: !_pressed,
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Maskot görseli. Dosya henüz eklenmediyse yumuşak bir yer tutucu gösterir.
class Mascot extends StatelessWidget {
  const Mascot({super.key, required this.size, this.mood = MascotMood.happy});

  final double size;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      mood.asset,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          _MascotPlaceholder(size: size),
    );
  }
}

enum MascotMood {
  happy('assets/images/fox_happy.png'),
  sad('assets/images/fox_sad.png');

  const MascotMood(this.asset);

  final String asset;
}

class _MascotPlaceholder extends StatelessWidget {
  const _MascotPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryFixed,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text('🦊', style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// "Yakında" kartı için kesik çizgili köşeli çerçeve.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    this.radius = AppRadius.lg,
    this.strokeWidth = 2,
    this.dash = 8,
    this.gap = 7,
  });

  final Color color;
  final double radius;
  final double strokeWidth;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final rect = Offset.zero & size;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect.deflate(strokeWidth / 2),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.strokeWidth != strokeWidth;
}
