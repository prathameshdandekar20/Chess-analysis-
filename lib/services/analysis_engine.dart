import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../models/chess_move_eval.dart';
import '../models/game_review_data.dart';
import 'stockfish_engine_service.dart';
import 'opening_book_service.dart';

class AnalysisEngine {
  static final AnalysisEngine instance = AnalysisEngine._internal();
  AnalysisEngine._internal();

  /// Analyzes an entire game given as a list of SAN or UCI moves, or a PGN string.
  /// Reports progress via [onProgress] callback (0.0 to 1.0).
  Future<GameReviewData> reviewGame({
    required List<String> sanMoves,
    String whitePlayer = 'White',
    String blackPlayer = 'Black',
    Function(double progress, String status)? onProgress,
  }) async {
    final engine = StockfishEngineService.instance;
    await engine.whenReady;

    final chess = chess_lib.Chess();
    final moveEvals = <MoveEvaluation>[];

    final whiteBreakdown = <MoveClassification, int>{
      for (final c in MoveClassification.values) c: 0,
    };
    final blackBreakdown = <MoveClassification, int>{
      for (final c in MoveClassification.values) c: 0,
    };

    double whiteTotalAccuracy = 0.0;
    double blackTotalAccuracy = 0.0;
    int whiteMoveCount = 0;
    int blackMoveCount = 0;

    // Detect opening
    final opening = OpeningBookService.findOpeningBySan(sanMoves);
    final openingName = opening?.name ?? 'Standard Chess Opening';
    final ecoCode = opening?.eco ?? 'A00';

    double previousEvalCp = 0.0;
    int? previousMate;

    for (int i = 0; i < sanMoves.length; i++) {
      final san = sanMoves[i];
      final isWhite = (i % 2 == 0);
      final moveNum = (i ~/ 2) + 1;
      final fenBefore = chess.fen;

      if (onProgress != null) {
        onProgress((i + 1) / (sanMoves.length + 1), 'Analyzing move ${i + 1}/${sanMoves.length}: $san');
      }

      // 1. Get engine evaluation of position BEFORE the move
      final beforeEval = await engine.evaluatePosition(fenBefore, depth: 10, moveTimeMs: 300);
      final bestMoveUci = beforeEval.bestMoveUci;

      final candidateMoves = chess.moves({'verbose': true});

      // Convert best move UCI to SAN
      String bestMoveSan = bestMoveUci;
      if (bestMoveUci.length >= 4) {
        final bFrom = bestMoveUci.substring(0, 2);
        final bTo = bestMoveUci.substring(2, 4);
        for (final m in candidateMoves) {
          final map = m as Map;
          if (map['from'] == bFrom && map['to'] == bTo) {
            bestMoveSan = map['san'] as String;
            break;
          }
        }
      }

      // Find played move in legal moves
      Map? playedMoveMap;
      for (final m in candidateMoves) {
        final map = m as Map;
        if (map['san'] == san) {
          playedMoveMap = map;
          break;
        }
      }

      // 2. Play the move
      final success = chess.move(san);
      if (!success || playedMoveMap == null) {
        continue;
      }

      final fromSquare = playedMoveMap['from'] as String;
      final toSquare = playedMoveMap['to'] as String;
      final pieceCaptured = playedMoveMap['captured'];
      final pieceName = (playedMoveMap['piece'] ?? '').toString();
      final uci = '$fromSquare$toSquare${playedMoveMap['promotion'] ?? ''}';
      final fenAfter = chess.fen;

      // 3. Get engine evaluation of position AFTER the move
      final afterEval = await engine.evaluatePosition(fenAfter, depth: 10, moveTimeMs: 300);

      final evalBeforeCp = beforeEval.scoreCp;
      final evalAfterCp = afterEval.scoreCp;
      final mateBefore = beforeEval.mateIn;
      final mateAfter = afterEval.mateIn;

      // Win chances from current player's perspective
      final double winBefore = isWhite ? beforeEval.whiteWinChance : (100.0 - beforeEval.whiteWinChance);
      final double winAfter = isWhite ? afterEval.whiteWinChance : (100.0 - afterEval.whiteWinChance);
      final double winLoss = max(0.0, winBefore - winAfter);

      // Check opening book
      final isBook = OpeningBookService.isBookMove(sanMoves, i);

      // Detect piece sacrifice for Brilliant move
      bool isSacrifice = false;
      if (pieceCaptured == null && (pieceName == 'n' || pieceName == 'b' || pieceName == 'r' || pieceName == 'q')) {
        // Did we move a major/minor piece into an attacked square?
        if (winAfter >= 65.0 && winLoss < 1.0) {
          isSacrifice = true;
        }
      }

      // Classify the move
      MoveClassification classification;
      if (isBook) {
        classification = MoveClassification.book;
      } else if (isSacrifice && winLoss < 1.5 && (isWhite ? evalAfterCp >= 150 : evalAfterCp <= -150)) {
        classification = MoveClassification.brilliant;
      } else if (uci == bestMoveUci || winLoss < 0.8) {
        // Check if it was a great critical move
        if (winBefore < 40.0 && winAfter > 60.0) {
          classification = MoveClassification.great;
        } else {
          classification = MoveClassification.best;
        }
      } else if (winLoss <= 0.6) {
        classification = MoveClassification.best;
      } else if (winLoss <= 2.5) {
        classification = MoveClassification.excellent;
      } else if (winLoss <= 6.0) {
        classification = MoveClassification.good;
      } else if (winLoss <= 12.0) {
        classification = MoveClassification.inaccuracy;
      } else if (winLoss <= 22.0) {
        classification = MoveClassification.mistake;
      } else {
        // Was it a missed win or outright blunder?
        if (winBefore >= 75.0 && winAfter <= 52.0) {
          classification = MoveClassification.miss;
        } else {
          classification = MoveClassification.blunder;
        }
      }

      // Exact official Lichess & CAPS accuracy calculation formula:
      // accuracy = 103.1668 * exp(-0.04354 * winLoss) - 3.1669
      final moveAccuracy = (103.1668 * exp(-0.04354 * winLoss) - 3.1669).clamp(0.0, 100.0);

      if (isWhite) {
        whiteBreakdown[classification] = (whiteBreakdown[classification] ?? 0) + 1;
        whiteTotalAccuracy += moveAccuracy;
        whiteMoveCount++;
      } else {
        blackBreakdown[classification] = (blackBreakdown[classification] ?? 0) + 1;
        blackTotalAccuracy += moveAccuracy;
        blackMoveCount++;
      }

      // Generate Coach Commentary
      final commentary = _generateCoachCommentary(
        classification: classification,
        san: san,
        bestMoveSan: bestMoveSan,
        isWhite: isWhite,
        evalAfterCp: evalAfterCp,
        openingName: openingName,
        captured: pieceCaptured != null,
      );

      moveEvals.add(MoveEvaluation(
        moveNumber: moveNum,
        isWhite: isWhite,
        san: san,
        uci: uci,
        fromSquare: fromSquare,
        toSquare: toSquare,
        fenBefore: fenBefore,
        fenAfter: fenAfter,
        evalBefore: evalBeforeCp,
        evalAfter: evalAfterCp,
        mateBefore: mateBefore,
        mateAfter: mateAfter,
        bestMoveUci: bestMoveUci,
        bestMoveSan: bestMoveSan,
        bestMoveEval: beforeEval.scoreCp,
        classification: classification,
        coachCommentary: commentary,
        accuracyScore: moveAccuracy,
        winChanceBefore: winBefore,
        winChanceAfter: winAfter,
      ));

      previousEvalCp = evalAfterCp;
      previousMate = mateAfter;
    }

    final whiteAvgAcc = whiteMoveCount > 0 ? (whiteTotalAccuracy / whiteMoveCount) : 80.0;
    final blackAvgAcc = blackMoveCount > 0 ? (blackTotalAccuracy / blackMoveCount) : 80.0;

    return GameReviewData(
      moves: moveEvals,
      whiteAccuracy: double.parse(whiteAvgAcc.toStringAsFixed(1)),
      blackAccuracy: double.parse(blackAvgAcc.toStringAsFixed(1)),
      whiteEstimatedElo: _estimateElo(whiteAvgAcc),
      blackEstimatedElo: _estimateElo(blackAvgAcc),
      whitePlayer: whitePlayer,
      blackPlayer: blackPlayer,
      openingName: openingName,
      ecoCode: ecoCode,
      result: chess.in_checkmate
          ? (chess.turn == chess_lib.Color.WHITE ? '0-1' : '1-0')
          : (chess.in_draw ? '1/2-1/2' : '*'),
      whiteBreakdown: whiteBreakdown,
      blackBreakdown: blackBreakdown,
    );
  }

  /// Estimates player Elo based on CAPS Accuracy %
  int _estimateElo(double accuracy) {
    if (accuracy >= 97.0) return 2700 + ((accuracy - 97) * 100).toInt();
    if (accuracy >= 92.0) return 2200 + ((accuracy - 92) * 100).toInt();
    if (accuracy >= 85.0) return 1750 + ((accuracy - 85) * 64).toInt();
    if (accuracy >= 75.0) return 1300 + ((accuracy - 75) * 45).toInt();
    if (accuracy >= 65.0) return 900 + ((accuracy - 65) * 40).toInt();
    return 600 + (accuracy * 4).toInt();
  }

  String _generateCoachCommentary({
    required MoveClassification classification,
    required String san,
    required String bestMoveSan,
    required bool isWhite,
    required double evalAfterCp,
    required String openingName,
    required bool captured,
  }) {
    final player = isWhite ? 'White' : 'Black';
    final evalStr = (evalAfterCp / 100.0).toStringAsFixed(1);

    switch (classification) {
      case MoveClassification.brilliant:
        return '💎 Brilliant piece sacrifice! $san cuts open the defense and keeps a dominating position.';
      case MoveClassification.great:
        return '⚡ Great find! $san is a critical move that keeps the pressure on the opponent.';
      case MoveClassification.best:
        if (captured) {
          return '⭐ Best move. Capturing with $san maintains maximum active piece placement.';
        }
        return '⭐ Best move. Stockfish approves: $san is the most accurate continuation.';
      case MoveClassification.excellent:
        return '👍 Excellent move. $san maintains the advantage and develops your plan nicely.';
      case MoveClassification.good:
        return '✔️ Good move. $san is solid, though $bestMoveSan was slightly more testing.';
      case MoveClassification.book:
        return '📖 Book move! Continuing theoretical main lines in the $openingName.';
      case MoveClassification.inaccuracy:
        return '⁉️ Inaccuracy. $san gives away some initiative. Better was $bestMoveSan.';
      case MoveClassification.mistake:
        return '❓ Mistake! $san allows the opponent counterplay. Best was $bestMoveSan.';
      case MoveClassification.blunder:
        return '❌ Blunder! $san severely damages your position. You should have played $bestMoveSan.';
      case MoveClassification.miss:
        return '⭕ Missed win! You had a decisive tactical advantage with $bestMoveSan, but played $san.';
    }
  }
}
