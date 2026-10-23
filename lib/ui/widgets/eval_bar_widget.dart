import 'dart:math';
import 'package:flutter/material.dart';

class EvalBarWidget extends StatelessWidget {
  final double evalCp; // centipawns from White's perspective (+150 = +1.5)
  final int? mateIn; // Mate in X
  final bool isFlipped; // True if Black is at the bottom
  final double height;
  final double width;

  const EvalBarWidget({
    super.key,
    required this.evalCp,
    this.mateIn,
    this.isFlipped = false,
    this.height = 360,
    this.width = 24,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate White's fraction [0.0, 1.0]
    double whiteFraction;
    String label;

    if (mateIn != null) {
      if (mateIn! > 0) {
        whiteFraction = 1.0;
        label = 'M${mateIn!.abs()}';
      } else {
        whiteFraction = 0.0;
        label = '-M${mateIn!.abs()}';
      }
    } else {
      // Sigmoid mapping
      final winPercent = 1.0 / (1.0 + pow(10, -evalCp / 400.0));
      whiteFraction = winPercent.clamp(0.04, 0.96);

      final val = (evalCp / 100.0).abs();
      if (evalCp > 0) {
        label = '+${val.toStringAsFixed(1)}';
      } else if (evalCp < 0) {
        label = '-${val.toStringAsFixed(1)}';
      } else {
        label = '0.0';
      }
    }

    final effectiveWhiteFraction = isFlipped ? (1.0 - whiteFraction) : whiteFraction;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF262421), // Black eval bar background
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: isFlipped ? Alignment.topCenter : Alignment.bottomCenter,
        children: [
          // White Fill
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            heightFactor: effectiveWhiteFraction,
            widthFactor: 1.0,
            alignment: isFlipped ? Alignment.topCenter : Alignment.bottomCenter,
            child: Container(
              color: const Color(0xFFFFFFFF),
            ),
          ),

          // Label indicator (positioned at edge or center)
          Positioned(
            bottom: isFlipped ? null : 6,
            top: isFlipped ? 6 : null,
            child: Text(
              label,
              style: TextStyle(
                color: effectiveWhiteFraction > 0.5 ? Colors.black : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
