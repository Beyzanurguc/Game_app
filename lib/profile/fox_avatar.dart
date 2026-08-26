import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/squishy.dart';
import 'fox_items.dart';

/// Maskot görselinin en/boy oranı (1223 x 1286).
const _foxAspect = 1223 / 1286;

/// Aksesuarların oturacağı noktalar — hepsi görselin kutusuna orandır.
///
/// Değerler `assets/images/fox_happy.png` üzerinden ölçüldü: kafanın tepesi,
/// gözlerin merkezi ve boyundaki bandana hizası.
const _headTop = Offset(0.405, 0.185);
const _leftEye = Offset(0.323, 0.327);
const _rightEye = Offset(0.465, 0.302);
const _neck = Offset(0.462, 0.505);

/// Tilkinin kafası hafifçe sağa yatık; aksesuarlar da aynı açıyla durur.
const _headTilt = -0.183;

/// Boyundaki bandana hizasının açısı.
const _neckTilt = -0.21;

/// Takılı aksesuarlarıyla birlikte maskot.
///
/// [size] görselin yüksekliğidir; genişlik oranla hesaplanır, böylece
/// aksesuarlar her boyutta aynı yere oturur.
class FoxAvatar extends StatelessWidget {
  const FoxAvatar({
    super.key,
    required this.size,
    this.items = const [],
    this.mood = MascotMood.happy,
  });

  final double size;
  final List<FoxItem> items;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size * _foxAspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Mascot(size: size, mood: mood),
          if (items.isNotEmpty)
            IgnorePointer(
              child: CustomPaint(painter: FoxItemPainter(items: items)),
            ),
        ],
      ),
    );
  }
}

/// Aksesuarları maskotun üzerine çizer.
///
/// Ölçüler yalnızca kutunun yüksekliğinden türetilir; böylece daireler her
/// boyutta daire kalır.
class FoxItemPainter extends CustomPainter {
  const FoxItemPainter({required this.items});

  final List<FoxItem> items;

  @override
  void paint(Canvas canvas, Size size) {
    // Boyun -> şapka -> gözlük sırası: üstteki aksesuar önde kalsın.
    for (final slot in [FoxSlot.neck, FoxSlot.hat, FoxSlot.glasses]) {
      for (final item in items) {
        if (item.slot == slot) _paintItem(canvas, size, item);
      }
    }
  }

  void _paintItem(Canvas canvas, Size size, FoxItem item) {
    switch (item.shape) {
      case FoxShape.beanie:
        _inFrame(canvas, size, _headTop, _headTilt, (c, u) {
          _beanie(c, u, item);
        });
      case FoxShape.partyHat:
        _inFrame(canvas, size, _headTop, _headTilt, (c, u) {
          _partyHat(c, u, item);
        });
      case FoxShape.topHat:
        _inFrame(canvas, size, _headTop, _headTilt, (c, u) {
          _topHat(c, u, item);
        });
      case FoxShape.crown:
        _inFrame(canvas, size, _headTop, _headTilt, (c, u) {
          _crown(c, u, item);
        });
      case FoxShape.roundGlasses:
      case FoxShape.sunglasses:
      case FoxShape.heartGlasses:
        _inFrame(canvas, size, _eyeCenter, _headTilt, (c, u) {
          _glasses(c, u, item);
        });
      case FoxShape.scarf:
        _inFrame(canvas, size, _neck, _neckTilt, (c, u) {
          _scarf(c, u, item);
        });
      case FoxShape.bowTie:
        _inFrame(canvas, size, _neck, _neckTilt, (c, u) {
          _bowTie(c, u, item);
        });
      case FoxShape.medal:
        _inFrame(canvas, size, _neck, _neckTilt, (c, u) {
          _medal(c, u, item);
        });
    }
  }

  static Offset get _eyeCenter => Offset(
    (_leftEye.dx + _rightEye.dx) / 2,
    (_leftEye.dy + _rightEye.dy) / 2,
  );

  /// Çizimi [anchor] noktasına taşır, [tilt] kadar döndürür ve birim olarak
  /// kutu yüksekliğini verir. Şekiller böylece sade yerel koordinatlarla
  /// yazılabiliyor.
  void _inFrame(
    Canvas canvas,
    Size size,
    Offset anchor,
    double tilt,
    void Function(Canvas canvas, double unit) body,
  ) {
    canvas.save();
    canvas.translate(anchor.dx * size.width, anchor.dy * size.height);
    canvas.rotate(tilt);
    body(canvas, size.height);
    canvas.restore();
  }

  // --- Şapkalar -------------------------------------------------------------

  void _beanie(Canvas canvas, double u, FoxItem item) {
    final fill = Paint()..color = item.color;
    final band = Paint()..color = item.accent;

    final cap = Path()
      ..moveTo(-0.198 * u, 0.01 * u)
      ..cubicTo(
        -0.21 * u,
        -0.175 * u,
        0.21 * u,
        -0.175 * u,
        0.198 * u,
        0.01 * u,
      )
      ..close();
    canvas.drawPath(cap, fill);

    // Kalın kenar katlaması — kaşların üstünde kalır.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-0.205 * u, -0.035 * u, 0.205 * u, 0.02 * u),
        Radius.circular(0.03 * u),
      ),
      band,
    );

    // Ponpon; açık zeminde kaybolmaması için ince çerçeveli.
    final pom = Offset(0, -0.13 * u);
    canvas.drawCircle(pom, 0.04 * u, band);
    canvas.drawCircle(
      pom,
      0.04 * u,
      Paint()
        ..color = item.color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.008 * u,
    );
  }

  void _partyHat(Canvas canvas, double u, FoxItem item) {
    final cone = Path()
      ..moveTo(-0.17 * u, 0.045 * u)
      ..lineTo(0, -0.30 * u)
      ..lineTo(0.17 * u, 0.045 * u)
      ..close();
    canvas.drawPath(cone, Paint()..color = item.color);

    // Şeritler.
    final stripe = Paint()
      ..color = item.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.02 * u
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.clipPath(cone);
    for (var i = 0; i < 3; i++) {
      final y = (-0.22 + i * 0.09) * u;
      canvas.drawLine(
        Offset(-0.2 * u, y),
        Offset(0.2 * u, y - 0.05 * u),
        stripe,
      );
    }
    canvas.restore();

    canvas.drawCircle(
      Offset(0, -0.305 * u),
      0.035 * u,
      Paint()..color = item.accent,
    );
    canvas.drawPath(
      cone,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.008 * u,
    );
  }

  void _topHat(Canvas canvas, double u, FoxItem item) {
    final fill = Paint()..color = item.color;

    // Kenar.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, 0.03 * u),
        width: 0.47 * u,
        height: 0.09 * u,
      ),
      fill,
    );
    // Silindir.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-0.145 * u, -0.25 * u, 0.145 * u, 0.03 * u),
        Radius.circular(0.02 * u),
      ),
      fill,
    );
    // Kurdele.
    canvas.drawRect(
      Rect.fromLTRB(-0.145 * u, -0.06 * u, 0.145 * u, 0.005 * u),
      Paint()..color = item.accent,
    );
  }

  void _crown(Canvas canvas, double u, FoxItem item) {
    final crown = Path()
      ..moveTo(-0.19 * u, 0.05 * u)
      ..lineTo(-0.19 * u, -0.07 * u)
      ..lineTo(-0.10 * u, -0.01 * u)
      ..lineTo(0, -0.17 * u)
      ..lineTo(0.10 * u, -0.01 * u)
      ..lineTo(0.19 * u, -0.07 * u)
      ..lineTo(0.19 * u, 0.05 * u)
      ..close();
    canvas.drawPath(crown, Paint()..color = item.color);
    canvas.drawPath(
      crown,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.008 * u,
    );

    final jewel = Paint()..color = item.accent;
    canvas.drawCircle(Offset(0, -0.185 * u), 0.028 * u, jewel);
    canvas.drawCircle(Offset(-0.19 * u, -0.085 * u), 0.022 * u, jewel);
    canvas.drawCircle(Offset(0.19 * u, -0.085 * u), 0.022 * u, jewel);
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(Offset(i * 0.075 * u, 0.025 * u), 0.016 * u, jewel);
    }
  }

  // --- Gözlükler ------------------------------------------------------------

  void _glasses(Canvas canvas, double u, FoxItem item) {
    // Gözler arası mesafenin yarısı.
    const half = 0.0685;
    final left = Offset(-half * u, 0);
    final right = Offset(half * u, 0);

    final frame = Paint()
      ..color = item.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.012 * u
      ..strokeCap = StrokeCap.round;

    switch (item.shape) {
      case FoxShape.sunglasses:
        final lens = Paint()..color = item.color;
        for (final center in [left, right]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: center,
                width: 0.115 * u,
                height: 0.082 * u,
              ),
              Radius.circular(0.025 * u),
            ),
            lens,
          );
          // Cam parıltısı.
          canvas.drawLine(
            center + Offset(-0.035 * u, 0.018 * u),
            center + Offset(0.005 * u, -0.022 * u),
            Paint()
              ..color = item.accent.withValues(alpha: 0.75)
              ..strokeWidth = 0.01 * u
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawLine(
          left + Offset(0.055 * u, -0.01 * u),
          right + Offset(-0.055 * u, -0.01 * u),
          frame,
        );
      case FoxShape.heartGlasses:
        for (final center in [left, right]) {
          canvas.drawPath(
            _heart(center, 0.105 * u),
            Paint()..color = item.color,
          );
          canvas.drawCircle(
            center + Offset(-0.022 * u, -0.008 * u),
            0.012 * u,
            Paint()..color = item.accent.withValues(alpha: 0.8),
          );
        }
        canvas.drawLine(
          left + Offset(0.05 * u, -0.012 * u),
          right + Offset(-0.05 * u, -0.012 * u),
          frame,
        );
      default:
        final glass = Paint()..color = item.accent.withValues(alpha: 0.35);
        for (final center in [left, right]) {
          canvas.drawCircle(center, 0.05 * u, glass);
          canvas.drawCircle(center, 0.05 * u, frame);
        }
        canvas.drawLine(
          left + Offset(0.05 * u, 0),
          right + Offset(-0.05 * u, 0),
          frame,
        );
    }

    // Saplar kulaklara doğru uzanır.
    canvas.drawLine(
      left + Offset(-0.055 * u, -0.005 * u),
      left + Offset(-0.11 * u, -0.03 * u),
      frame,
    );
    canvas.drawLine(
      right + Offset(0.055 * u, -0.005 * u),
      right + Offset(0.105 * u, -0.03 * u),
      frame,
    );
  }

  Path _heart(Offset center, double size) {
    final w = size / 2;
    return Path()
      ..moveTo(center.dx, center.dy + w * 0.85)
      ..cubicTo(
        center.dx - w * 1.6,
        center.dy - w * 0.2,
        center.dx - w * 0.55,
        center.dy - w * 1.15,
        center.dx,
        center.dy - w * 0.35,
      )
      ..cubicTo(
        center.dx + w * 0.55,
        center.dy - w * 1.15,
        center.dx + w * 1.6,
        center.dy - w * 0.2,
        center.dx,
        center.dy + w * 0.85,
      )
      ..close();
  }

  // --- Boyun aksesuarları ---------------------------------------------------

  void _scarf(Canvas canvas, double u, FoxItem item) {
    final fill = Paint()..color = item.color;
    final stripe = Paint()
      ..color = item.accent
      ..strokeWidth = 0.018 * u
      ..strokeCap = StrokeCap.round;

    final band = RRect.fromRectAndRadius(
      Rect.fromLTRB(-0.15 * u, -0.05 * u, 0.15 * u, 0.05 * u),
      Radius.circular(0.05 * u),
    );
    canvas.drawRRect(band, fill);

    // Sarkan uç.
    final tail = RRect.fromRectAndRadius(
      Rect.fromLTRB(0.01 * u, 0.0, 0.088 * u, 0.17 * u),
      Radius.circular(0.032 * u),
    );
    canvas.drawRRect(tail, fill);

    canvas.save();
    canvas.clipRRect(tail);
    for (var i = 0; i < 3; i++) {
      final y = (0.045 + i * 0.05) * u;
      canvas.drawLine(Offset(0, y), Offset(0.1 * u, y), stripe);
    }
    canvas.restore();

    canvas.save();
    canvas.clipRRect(band);
    for (var i = -2; i <= 2; i++) {
      final x = i * 0.06 * u;
      canvas.drawLine(
        Offset(x, -0.06 * u),
        Offset(x - 0.02 * u, 0.06 * u),
        stripe,
      );
    }
    canvas.restore();
  }

  void _bowTie(Canvas canvas, double u, FoxItem item) {
    final fill = Paint()..color = item.color;

    final wings = Path()
      ..moveTo(-0.13 * u, -0.075 * u)
      ..lineTo(-0.022 * u, 0)
      ..lineTo(-0.13 * u, 0.075 * u)
      ..close()
      ..moveTo(0.13 * u, -0.075 * u)
      ..lineTo(0.022 * u, 0)
      ..lineTo(0.13 * u, 0.075 * u)
      ..close();
    canvas.drawPath(wings, fill);
    canvas.drawPath(
      wings,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.007 * u,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 0.05 * u, height: 0.07 * u),
        Radius.circular(0.02 * u),
      ),
      Paint()..color = item.accent,
    );
  }

  void _medal(Canvas canvas, double u, FoxItem item) {
    final ribbon = Paint()
      ..color = item.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.022 * u
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(-0.105 * u, -0.02 * u),
      Offset(-0.01 * u, 0.16 * u),
      ribbon,
    );
    canvas.drawLine(
      Offset(0.105 * u, -0.02 * u),
      Offset(0.01 * u, 0.16 * u),
      ribbon,
    );

    final center = Offset(0, 0.20 * u);
    canvas.drawCircle(center, 0.075 * u, Paint()..color = item.color);
    canvas.drawCircle(
      center,
      0.075 * u,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.008 * u,
    );
    canvas.drawPath(
      _star(center, 0.045 * u),
      Paint()..color = item.accent.withValues(alpha: 0.9),
    );
  }

  Path _star(Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(FoxItemPainter oldDelegate) =>
      !listEquals(oldDelegate.items, items);
}
