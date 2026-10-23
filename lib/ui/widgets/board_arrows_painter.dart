import 'dart:math';
import 'package:flutter/material.dart';

class ArrowData {
  final String from;
  final String to;
  final Color color;
  final double width;

  const ArrowData({
    required this.from,
    required this.to,
    required this.color,
    this.width = 7.0,
  });
}

class BoardArrowsPainter extends CustomPainter {
  final List<ArrowData> arrows;
  final bool isFlipped;

  BoardArrowsPainter({
    required this.arrows,
    this.isFlipped = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (arrows.isEmpty) return;

    final squareSize = size.width / 8.0;

    for (final arrow in arrows) {
      if (arrow.from.length < 2 || arrow.to.length < 2) continue;

      final p1 = _getSquareCenter(arrow.from, squareSize, isFlipped);
      final p2 = _getSquareCenter(arrow.to, squareSize, isFlipped);

      _drawArrow(canvas, p1, p2, arrow.color, arrow.width);
    }
  }

  Offset _getSquareCenter(String square, double squareSize, bool flipped) {
    final file = square[0].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(square[1]);

    final col = flipped ? (7 - file) : file;
    final row = flipped ? (rank - 1) : (8 - rank);

    return Offset(
      col * squareSize + squareSize / 2.0,
      row * squareSize + squareSize / 2.0,
    );
  }

  void _drawArrow(Canvas canvas, Offset p1, Offset p2, Color color, double width) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1.0) return;

    final unitX = dx / dist;
    final unitY = dy / dist;

    // Arrowhead dimensions
    final headLength = width * 3.0;
    final headWidth = width * 2.8;

    // Shorten end point so arrowhead points right into center
    final shaftEnd = Offset(
      p2.dx - unitX * (headLength * 0.7),
      p2.dy - unitY * (headLength * 0.7),
    );

    final shaftPaint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw shaft
    canvas.drawLine(p1, shaftEnd, shaftPaint);

    // Draw arrowhead
    final perpX = -unitY;
    final perpY = unitX;

    final headBase = Offset(
      p2.dx - unitX * headLength,
      p2.dy - unitY * headLength,
    );

    final wing1 = Offset(
      headBase.dx + perpX * (headWidth / 2.0),
      headBase.dy + perpY * (headWidth / 2.0),
    );

    final wing2 = Offset(
      headBase.dx - perpX * (headWidth / 2.0),
      headBase.dy - perpY * (headWidth / 2.0),
    );

    final headPath = Path()
      ..moveTo(p2.dx, p2.dy)
      ..lineTo(wing1.dx, wing1.dy)
      ..lineTo(headBase.dx + unitX * (headLength * 0.2), headBase.dy + unitY * (headLength * 0.2))
      ..lineTo(wing2.dx, wing2.dy)
      ..close();

    final headPaint = Paint()
      ..color = color.withOpacity(0.95)
      ..style = PaintingStyle.fill;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(headPath, shadowPaint);

    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant BoardArrowsPainter oldDelegate) {
    return oldDelegate.arrows != arrows || oldDelegate.isFlipped != isFlipped;
  }
}
