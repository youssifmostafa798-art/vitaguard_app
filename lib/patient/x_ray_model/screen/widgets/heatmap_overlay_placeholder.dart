import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// NOTE: Placeholder saliency-style overlay until the model exposes real heatmap tensors.
class HeatmapOverlayPlaceholder extends StatelessWidget {
  const HeatmapOverlayPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // NOTE: Use LayoutBuilder so [CustomPaint] gets a finite size inside [Stack].
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _RadialHeatmapPainter(),
          );
        },
      ),
    );
  }
}

class _RadialHeatmapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.42);
    final radius = math.min(size.width, size.height) * 0.38;

    final gradient = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.red.withValues(alpha: 0.45),
        Colors.orange.withValues(alpha: 0.22),
        Colors.transparent,
      ],
      [0.0, 0.45, 1.0],
    );

    final paint = Paint()
      ..shader = gradient
      ..blendMode = BlendMode.srcATop;

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
