import 'package:flutter/material.dart';

import 'pocket_theme.dart';

/// Red Box's Zen mark: five soft petals shelter a tiny coral square.
/// Kept as vector geometry so the mark stays crisp at every device scale.
class ZenMark extends StatelessWidget {
  const ZenMark({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _ZenMarkPainter()),
    ),
  );
}

class _ZenMarkPainter extends CustomPainter {
  const _ZenMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    final fill = Paint()..color = PocketColors.zenSurface;
    final outline = Paint()
      ..color = PocketColors.zenInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void petal(Path path) {
      canvas.drawPath(path, fill);
      canvas.drawPath(path, outline);
    }

    petal(
      Path()
        ..moveTo(16, 3)
        ..cubicTo(11, 7, 9.5, 11, 10.5, 15)
        ..cubicTo(11.1, 18, 13.2, 20.6, 16, 22)
        ..cubicTo(18.8, 20.6, 20.9, 18, 21.5, 15)
        ..cubicTo(22.5, 11, 21, 7, 16, 3)
        ..close(),
    );
    petal(
      Path()
        ..moveTo(5, 9)
        ..cubicTo(11, 9, 15, 14, 16, 23)
        ..cubicTo(8, 23, 3.5, 18, 5, 9)
        ..close(),
    );
    petal(
      Path()
        ..moveTo(27, 9)
        ..cubicTo(21, 9, 17, 14, 16, 23)
        ..cubicTo(24, 23, 28.5, 18, 27, 9)
        ..close(),
    );
    petal(
      Path()
        ..moveTo(2.5, 17)
        ..cubicTo(9, 16.5, 14.5, 20, 16, 28)
        ..cubicTo(8, 28, 3.5, 24.5, 2.5, 17)
        ..close(),
    );
    petal(
      Path()
        ..moveTo(29.5, 17)
        ..cubicTo(23, 16.5, 17.5, 20, 16, 28)
        ..cubicTo(24, 28, 28.5, 24.5, 29.5, 17)
        ..close(),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12.5, 18, 7, 7),
        const Radius.circular(1.8),
      ),
      Paint()..color = PocketColors.redDepth,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12.5, 17, 7, 7),
        const Radius.circular(1.8),
      ),
      Paint()..color = PocketColors.red,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ZenMarkPainter oldDelegate) => false;
}
