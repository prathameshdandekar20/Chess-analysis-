import 'chess_move_eval.dart';

/// Full Game Review Report matching Chess.com CAPS analysis
class GameReviewData {
  final List<MoveEvaluation> moves;
  final double whiteAccuracy;
  final double blackAccuracy;
  final int whiteEstimatedElo;
  final int blackEstimatedElo;
  final String whitePlayer;
  final String blackPlayer;
  final String openingName;
  final String ecoCode;
  final String result;
  final Map<MoveClassification, int> whiteBreakdown;
  final Map<MoveClassification, int> blackBreakdown;

  const GameReviewData({
    required this.moves,
    required this.whiteAccuracy,
    required this.blackAccuracy,
    required this.whiteEstimatedElo,
    required this.blackEstimatedElo,
    this.whitePlayer = 'White',
    this.blackPlayer = 'Black',
    this.openingName = 'Standard Chess Game',
    this.ecoCode = 'A00',
    this.result = '*',
    required this.whiteBreakdown,
    required this.blackBreakdown,
  });

  /// Key moments in the game: Blunders, Mistakes, Missed Wins, and Brilliant moves
  List<int> get keyMomentIndices {
    final list = <int>[];
    for (int i = 0; i < moves.length; i++) {
      final c = moves[i].classification;
      if (c == MoveClassification.blunder ||
          c == MoveClassification.mistake ||
          c == MoveClassification.miss ||
          c == MoveClassification.brilliant) {
        list.add(i);
      }
    }
    return list;
  }

  int countFor(bool isWhite, MoveClassification classification) {
    final map = isWhite ? whiteBreakdown : blackBreakdown;
    return map[classification] ?? 0;
  }
}
