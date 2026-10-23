import 'package:flutter/material.dart';

/// Chess.com style move classification
enum MoveClassification {
  brilliant,
  great,
  best,
  excellent,
  good,
  book,
  inaccuracy,
  mistake,
  blunder,
  miss,
}

extension MoveClassificationX on MoveClassification {
  String get symbol {
    switch (this) {
      case MoveClassification.brilliant:
        return '!!';
      case MoveClassification.great:
        return '!';
      case MoveClassification.best:
        return '★';
      case MoveClassification.excellent:
        return '✓';
      case MoveClassification.good:
        return '•';
      case MoveClassification.book:
        return '📖';
      case MoveClassification.inaccuracy:
        return '?!';
      case MoveClassification.mistake:
        return '?';
      case MoveClassification.blunder:
        return '??';
      case MoveClassification.miss:
        return '✗';
    }
  }

  String get displayName {
    switch (this) {
      case MoveClassification.brilliant:
        return 'Brilliant';
      case MoveClassification.great:
        return 'Great Move';
      case MoveClassification.best:
        return 'Best';
      case MoveClassification.excellent:
        return 'Excellent';
      case MoveClassification.good:
        return 'Good';
      case MoveClassification.book:
        return 'Book Move';
      case MoveClassification.inaccuracy:
        return 'Inaccuracy';
      case MoveClassification.mistake:
        return 'Mistake';
      case MoveClassification.blunder:
        return 'Blunder';
      case MoveClassification.miss:
        return 'Missed Win';
    }
  }

  Color get color {
    switch (this) {
      case MoveClassification.brilliant:
        return const Color(0xFF1BACA6); // Chess.com Cyan
      case MoveClassification.great:
        return const Color(0xFF5B8BBD); // Blue-teal
      case MoveClassification.best:
        return const Color(0xFF81B64C); // Chess.com Green
      case MoveClassification.excellent:
        return const Color(0xFF96BC4B); // Light green
      case MoveClassification.good:
        return const Color(0xFF979895); // Slate
      case MoveClassification.book:
        return const Color(0xFFD5A47C); // Wood / Book brown
      case MoveClassification.inaccuracy:
        return const Color(0xFFF0C15C); // Yellow
      case MoveClassification.mistake:
        return const Color(0xFFE6912C); // Orange
      case MoveClassification.blunder:
        return const Color(0xFFCA3431); // Red
      case MoveClassification.miss:
        return const Color(0xFFE84D8A); // Pink / Magenta
    }
  }

  IconData get icon {
    switch (this) {
      case MoveClassification.brilliant:
        return Icons.auto_awesome;
      case MoveClassification.great:
        return Icons.priority_high;
      case MoveClassification.best:
        return Icons.star;
      case MoveClassification.excellent:
        return Icons.thumb_up_alt_outlined;
      case MoveClassification.good:
        return Icons.check;
      case MoveClassification.book:
        return Icons.menu_book;
      case MoveClassification.inaccuracy:
        return Icons.help_outline;
      case MoveClassification.mistake:
        return Icons.warning_amber_rounded;
      case MoveClassification.blunder:
        return Icons.close;
      case MoveClassification.miss:
        return Icons.not_interested;
    }
  }

  bool get isNegative {
    return this == MoveClassification.inaccuracy ||
        this == MoveClassification.mistake ||
        this == MoveClassification.blunder ||
        this == MoveClassification.miss;
  }

  bool get isPositive {
    return this == MoveClassification.brilliant ||
        this == MoveClassification.great ||
        this == MoveClassification.best ||
        this == MoveClassification.excellent;
  }
}

/// Represents the deep analysis of a single move in a chess game
class MoveEvaluation {
  final int moveNumber; // e.g. 1, 2, 3...
  final bool isWhite;
  final String san; // e.g. "Nf3"
  final String uci; // e.g. "g1f3"
  final String fromSquare;
  final String toSquare;
  final String fenBefore;
  final String fenAfter;

  /// Evaluation from the perspective of White (in centipawns, e.g. +150 = +1.5)
  final double evalBefore;
  final double evalAfter;

  /// Mate in X moves (positive for White mate, negative for Black mate, null if no mate)
  final int? mateBefore;
  final int? mateAfter;

  final String bestMoveUci;
  final String bestMoveSan;
  final double bestMoveEval;

  final MoveClassification classification;
  final String coachCommentary;
  final double accuracyScore; // 0.0 - 100.0 for this move
  final double winChanceBefore; // 0.0 - 100.0
  final double winChanceAfter; // 0.0 - 100.0

  const MoveEvaluation({
    required this.moveNumber,
    required this.isWhite,
    required this.san,
    required this.uci,
    required this.fromSquare,
    required this.toSquare,
    required this.fenBefore,
    required this.fenAfter,
    required this.evalBefore,
    required this.evalAfter,
    this.mateBefore,
    this.mateAfter,
    required this.bestMoveUci,
    required this.bestMoveSan,
    required this.bestMoveEval,
    required this.classification,
    required this.coachCommentary,
    required this.accuracyScore,
    required this.winChanceBefore,
    required this.winChanceAfter,
  });

  /// Formats evaluation for display (e.g. "+1.4", "-0.8", "M3")
  String get displayEval {
    if (mateAfter != null) {
      return mateAfter! > 0 ? 'M${mateAfter!.abs()}' : '-M${mateAfter!.abs()}';
    }
    final cp = evalAfter / 100.0;
    if (cp > 0) {
      return '+${cp.toStringAsFixed(1)}';
    } else if (cp < 0) {
      return cp.toStringAsFixed(1);
    }
    return '0.0';
  }
}
