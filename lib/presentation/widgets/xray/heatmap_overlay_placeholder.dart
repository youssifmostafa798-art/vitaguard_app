import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// NOTE: Placeholder saliency-style overlay until the model exposes real heatmap tensors.
class HeatmapOverlayPlaceholder extends StatelessWidget {
  const HeatmapOverlayPlaceholder({
    super.key,
    this.emphasis = 0.8,
  });

  final double emphasis;

  @override
  Widget build(BuildContext context) {
    // NOTE: Use LayoutBuilder so [CustomPaint] gets a finite size inside [Stack].
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _PneumoniaCloudPainter(emphasis: emphasis),
          );
        },
      ),
    );
  }
}

class _PneumoniaCloudPainter extends CustomPainter {
  const _PneumoniaCloudPainter({required this.emphasis});

  final double emphasis;

  @override
  void paint(Canvas canvas, Size size) {
    final strength = emphasis.clamp(0.35, 1.0);
    final paint = Paint()..blendMode = BlendMode.screen;

    final cloudZones = <_CloudZone>[
      _CloudZone(
        center: Offset(size.width * 0.37, size.height * 0.39),
        radiusX: size.width * 0.14,
        radiusY: size.height * 0.15,
        color: Colors.amber.withValues(alpha: 0.18 * strength),
      ),
      _CloudZone(
        center: Offset(size.width * 0.33, size.height * 0.56),
        radiusX: size.width * 0.16,
        radiusY: size.height * 0.14,
        color: Colors.orange.withValues(alpha: 0.26 * strength),
      ),
      _CloudZone(
        center: Offset(size.width * 0.62, size.height * 0.42),
        radiusX: size.width * 0.12,
        radiusY: size.height * 0.13,
        color: Colors.amber.withValues(alpha: 0.16 * strength),
      ),
      _CloudZone(
        center: Offset(size.width * 0.66, size.height * 0.6),
        radiusX: size.width * 0.17,
        radiusY: size.height * 0.16,
        color: Colors.deepOrange.withValues(alpha: 0.28 * strength),
      ),
    ];

    for (final zone in cloudZones) {
      paint.shader = ui.Gradient.radial(
        zone.center,
        math.max(zone.radiusX, zone.radiusY),
        [
          zone.color,
          zone.color.withValues(alpha: zone.color.a * 0.45),
          Colors.transparent,
        ],
        const [0.0, 0.58, 1.0],
      );

      canvas.save();
      canvas.translate(zone.center.dx, zone.center.dy);
      canvas.rotate(zone.center.dx < size.width * 0.5 ? -0.18 : 0.18);
      canvas.translate(-zone.center.dx, -zone.center.dy);
      canvas.drawOval(
        Rect.fromCenter(
          center: zone.center,
          width: zone.radiusX * 2,
          height: zone.radiusY * 2,
        ),
        paint,
      );
      canvas.restore();
    }

    final contourPaint = Paint()
      ..color = Colors.orangeAccent.withValues(alpha: 0.22 * strength)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final leftContour = Path()
      ..moveTo(size.width * 0.24, size.height * 0.26)
      ..quadraticBezierTo(
        size.width * 0.16,
        size.height * 0.46,
        size.width * 0.26,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.64,
        size.width * 0.4,
        size.height * 0.36,
      );

    final rightContour = Path()
      ..moveTo(size.width * 0.76, size.height * 0.26)
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.46,
        size.width * 0.74,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.66,
        size.height * 0.64,
        size.width * 0.6,
        size.height * 0.36,
      );

    canvas.drawPath(leftContour, contourPaint);
    canvas.drawPath(rightContour, contourPaint);
  }

  @override
  bool shouldRepaint(covariant _PneumoniaCloudPainter oldDelegate) {
    return oldDelegate.emphasis != emphasis;
  }
}

class _CloudZone {
  const _CloudZone({
    required this.center,
    required this.radiusX,
    required this.radiusY,
    required this.color,
  });

  final Offset center;
  final double radiusX;
  final double radiusY;
  final Color color;
}
