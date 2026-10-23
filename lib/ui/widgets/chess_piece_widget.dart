import 'package:flutter/material.dart';

class ChessPieceWidget extends StatelessWidget {
  final String pieceType; // 'p', 'n', 'b', 'r', 'q', 'k'
  final bool isWhite;
  final double size;

  const ChessPieceWidget({
    super.key,
    required this.pieceType,
    required this.isWhite,
    required this.size,
  });

  String get _glyph {
    switch (pieceType.toLowerCase()) {
      case 'k':
        return isWhite ? '♔' : '♚';
      case 'q':
        return isWhite ? '♕' : '♛';
      case 'r':
        return isWhite ? '♖' : '♜';
      case 'b':
        return isWhite ? '♗' : '♝';
      case 'n':
        return isWhite ? '♘' : '♞';
      case 'p':
        return isWhite ? '♙' : '♟';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (pieceType.isEmpty) return const SizedBox.shrink();

    final pieceColor = isWhite ? const Color(0xFFFFFFFF) : const Color(0xFF1E1E1E);
    final shadowColor = isWhite ? Colors.black.withOpacity(0.35) : Colors.white.withOpacity(0.25);

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          _glyph,
          style: TextStyle(
            fontSize: size * 0.92,
            height: 1.0,
            color: pieceColor,
            shadows: [
              Shadow(
                color: shadowColor,
                offset: isWhite ? const Offset(1, 2) : const Offset(0, 1),
                blurRadius: isWhite ? 2.5 : 1.5,
              ),
              if (!isWhite)
                Shadow(
                  color: Colors.black.withOpacity(0.8),
                  offset: const Offset(1, 1),
                  blurRadius: 1.0,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
