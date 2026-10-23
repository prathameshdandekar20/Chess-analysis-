import 'package:flutter/material.dart';
import '../../models/chess_move_eval.dart';

enum MoveBadgeSize { small, regular, large }

class MoveBadgeWidget extends StatelessWidget {
  final MoveClassification classification;
  final MoveBadgeSize size;
  final bool showLabel;

  const MoveBadgeWidget({
    super.key,
    required this.classification,
    this.size = MoveBadgeSize.regular,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    double dimension;
    double fontSize;

    switch (size) {
      case MoveBadgeSize.small:
        dimension = 18.0;
        fontSize = 10.0;
        break;
      case MoveBadgeSize.regular:
        dimension = 26.0;
        fontSize = 13.0;
        break;
      case MoveBadgeSize.large:
        dimension = 36.0;
        fontSize = 18.0;
        break;
    }

    final badge = Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: classification.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: classification.color.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          classification.symbol,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );

    if (!showLabel) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 8),
        Text(
          classification.displayName,
          style: TextStyle(
            color: classification.color,
            fontWeight: FontWeight.bold,
            fontSize: fontSize + 1,
          ),
        ),
      ],
    );
  }
}
