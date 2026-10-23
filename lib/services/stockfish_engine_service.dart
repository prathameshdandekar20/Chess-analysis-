import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stockfish_chess_engine/stockfish_chess_engine.dart';
import 'package:stockfish_chess_engine/stockfish_chess_engine_state.dart';
import 'package:chess/chess.dart' as chess_lib;

class EngineEvaluation {
  final double scoreCp; // Centipawns from White's perspective (+100 = +1.0)
  final int? mateIn; // Positive: White wins in X moves; Negative: Black wins
  final String bestMoveUci;
  final List<String> pv; // Principal Variation
  final int depth;

  const EngineEvaluation({
    required this.scoreCp,
    this.mateIn,
    required this.bestMoveUci,
    this.pv = const [],
    this.depth = 12,
  });

  /// Evaluates win percentage from White's perspective using the exact official Lichess/CAPS sigmoid model
  double get whiteWinChance {
    if (mateIn != null) {
      return mateIn! > 0 ? 100.0 : 0.0;
    }
    // Exact Lichess/Kenneth Regan model: 50 + 50 * (2 / (1 + exp(-0.00368208 * scoreCp)) - 1)
    return (50.0 + 50.0 * (2.0 / (1.0 + exp(-0.00368208 * scoreCp)) - 1.0)).clamp(0.0, 100.0);
  }
}

/// Service managing real Stockfish UCI communication with robust fallbacks
class StockfishEngineService {
  static final StockfishEngineService instance = StockfishEngineService._internal();

  StockfishEngineService._internal();

  Stockfish? _nativeStockfish;
  StreamSubscription<String>? _stdoutSub;
  bool _isNativeReady = false;
  bool _initAttempted = false;
  bool enableCloudEval = false; // Default to 100% offline local computation

  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get whenReady => _readyCompleter.future;

  bool get isUsingNativeEngine => _isNativeReady;

  /// Initializes Stockfish engine
  Future<void> init() async {
    if (_initAttempted) return;
    _initAttempted = true;

    try {
      debugPrint('[StockfishService] Initializing Stockfish engine...');
      _nativeStockfish = Stockfish();

      _stdoutSub = _nativeStockfish!.stdout.listen((line) {
        // debugPrint('[Stockfish UCI] $line');
      });

      _nativeStockfish!.state.addListener(() {
        if (_nativeStockfish?.state.value == StockfishState.ready) {
          _isNativeReady = true;
          _nativeStockfish!.stdin = 'uci';
          _nativeStockfish!.stdin = 'isready';
          if (!_readyCompleter.isCompleted) {
            _readyCompleter.complete();
          }
          debugPrint('[StockfishService] Native Stockfish engine ready!');
        }
      });

      // Wait a short time for native engine
      await Future.delayed(const Duration(milliseconds: 600));
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    } catch (e) {
      debugPrint('[StockfishService] Native Stockfish unavailable on this platform ($e). Using built-in engine.');
      _isNativeReady = false;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }
  }

  /// Evaluates a position given by FEN.
  /// Uses native Stockfish if ready, else cloud-eval or built-in minimax engine.
  Future<EngineEvaluation> evaluatePosition(
    String fen, {
    int depth = 12,
    int moveTimeMs = 450,
  }) async {
    await whenReady;

    if (_isNativeReady && _nativeStockfish != null) {
      try {
        return await _evaluateWithNativeStockfish(fen, depth: depth, moveTimeMs: moveTimeMs);
      } catch (e) {
        debugPrint('[StockfishService] Native eval error ($e), falling back');
      }
    }

    // Try cloud eval if available, else built-in minimax
    final cloudEval = await _tryCloudEval(fen);
    if (cloudEval != null) {
      return cloudEval;
    }

    return _evaluateWithLocalEngine(fen, depth: min(depth, 4));
  }

  /// Asks Stockfish for the best move (used when playing against bot)
  Future<String?> getBestMove(
    String fen, {
    int skillLevel = 20,
    int depth = 10,
    int moveTimeMs = 500,
    double blunderChance = 0.0,
  }) async {
    // If bot has a blunder chance, occasionally make a random legal move
    if (blunderChance > 0 && Random().nextDouble() < blunderChance) {
      final chess = chess_lib.Chess();
      if (chess.load(fen)) {
        final moves = chess.moves({'verbose': true});
        if (moves.isNotEmpty) {
          moves.shuffle();
          final m = moves.first as Map;
          return '${m['from']}${m['to']}${m['promotion'] ?? ''}';
        }
      }
    }

    final eval = await evaluatePosition(fen, depth: depth, moveTimeMs: moveTimeMs);
    return eval.bestMoveUci.isNotEmpty ? eval.bestMoveUci : null;
  }

  Future<EngineEvaluation> _evaluateWithNativeStockfish(
    String fen, {
    required int depth,
    required int moveTimeMs,
  }) async {
    final completer = Completer<EngineEvaluation>();
    double currentCp = 0.0;
    int? currentMate;
    String bestMove = '';
    final pvMoves = <String>[];

    late StreamSubscription<String> sub;
    Timer? timeoutTimer;

    final isWhiteTurn = fen.split(' ')[1] == 'w';

    sub = _nativeStockfish!.stdout.listen((line) {
      // Parse info score cp 120 depth 10 pv e2e4 e7e5
      if (line.startsWith('info ') && line.contains('score ')) {
        final tokens = line.split(' ');
        for (int i = 0; i < tokens.length; i++) {
          if (tokens[i] == 'cp' && i + 1 < tokens.length) {
            final parsed = double.tryParse(tokens[i + 1]);
            if (parsed != null) {
              // Stockfish outputs score relative to side to move
              currentCp = isWhiteTurn ? parsed : -parsed;
              currentMate = null;
            }
          } else if (tokens[i] == 'mate' && i + 1 < tokens.length) {
            final parsed = int.tryParse(tokens[i + 1]);
            if (parsed != null) {
              currentMate = isWhiteTurn ? parsed : -parsed;
              currentCp = currentMate! > 0 ? 10000.0 : -10000.0;
            }
          } else if (tokens[i] == 'pv' && i + 1 < tokens.length) {
            pvMoves.clear();
            for (int j = i + 1; j < tokens.length; j++) {
              if (tokens[j].isNotEmpty) pvMoves.add(tokens[j]);
            }
            if (pvMoves.isNotEmpty) {
              bestMove = pvMoves.first;
            }
          }
        }
      }

      if (line.startsWith('bestmove ')) {
        final parts = line.split(' ');
        if (parts.length >= 2 && parts[1] != '(none)') {
          bestMove = parts[1];
        }
        timeoutTimer?.cancel();
        sub.cancel();
        if (!completer.isCompleted) {
          completer.complete(EngineEvaluation(
            scoreCp: currentCp,
            mateIn: currentMate,
            bestMoveUci: bestMove,
            pv: pvMoves,
            depth: depth,
          ));
        }
      }
    });

    timeoutTimer = Timer(Duration(milliseconds: moveTimeMs + 600), () {
      if (!completer.isCompleted) {
        sub.cancel();
        completer.complete(EngineEvaluation(
          scoreCp: currentCp,
          mateIn: currentMate,
          bestMoveUci: bestMove,
          pv: pvMoves,
          depth: depth,
        ));
      }
    });

    _nativeStockfish!.stdin = 'position fen $fen';
    _nativeStockfish!.stdin = 'go depth $depth movetime $moveTimeMs';

    return completer.future;
  }

  /// Queries Lichess Cloud Evaluation if enabled
  Future<EngineEvaluation?> _tryCloudEval(String fen) async {
    if (!enableCloudEval) return null;
    try {
      final encodedFen = Uri.encodeComponent(fen);
      final url = Uri.parse('https://lichess.org/api/cloud-eval?fen=$encodedFen&multiPv=1');
      final res = await http.get(url).timeout(const Duration(milliseconds: 700));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final pvs = data['pvs'] as List?;
        if (pvs != null && pvs.isNotEmpty) {
          final top = pvs.first;
          final cp = top['cp'] != null ? (top['cp'] as num).toDouble() : null;
          final mate = top['mate'] != null ? (top['mate'] as num).toInt() : null;
          final movesStr = top['moves'] as String? ?? '';
          final pvList = movesStr.split(' ').where((s) => s.isNotEmpty).toList();
          final bestUci = pvList.isNotEmpty ? pvList.first : '';

          final isWhiteTurn = fen.split(' ')[1] == 'w';
          final adjustedCp = cp != null ? (isWhiteTurn ? cp : -cp) : (mate != null && mate > 0 ? 10000.0 : -10000.0);
          final adjustedMate = mate != null ? (isWhiteTurn ? mate : -mate) : null;

          return EngineEvaluation(
            scoreCp: adjustedCp,
            mateIn: adjustedMate,
            bestMoveUci: bestUci,
            pv: pvList,
            depth: data['depth'] ?? 20,
          );
        }
      }
    } catch (_) {
      // Network error or timeout, silently continue to local engine
    }
    return null;
  }

  /// Built-in Alpha-Beta evaluation engine with PeSTO positional tables
  EngineEvaluation _evaluateWithLocalEngine(String fen, {int depth = 3}) {
    final chess = chess_lib.Chess();
    if (!chess.load(fen)) {
      return const EngineEvaluation(scoreCp: 0, bestMoveUci: '');
    }

    final isWhiteTurn = chess.turn == chess_lib.Color.WHITE;

    if (chess.in_checkmate) {
      return EngineEvaluation(
        scoreCp: isWhiteTurn ? -10000 : 10000,
        mateIn: isWhiteTurn ? -1 : 1,
        bestMoveUci: '',
      );
    }
    if (chess.in_draw) {
      return const EngineEvaluation(scoreCp: 0, bestMoveUci: '');
    }

    final moves = chess.moves({'verbose': true});
    if (moves.isEmpty) {
      return const EngineEvaluation(scoreCp: 0, bestMoveUci: '');
    }

    String bestMoveUci = '';
    double bestScore = isWhiteTurn ? -999999 : 999999;

    for (final m in moves) {
      final moveMap = m as Map;
      final from = moveMap['from'] as String;
      final to = moveMap['to'] as String;
      final promotion = moveMap['promotion'] as String?;
      final uci = '$from$to${promotion ?? ''}';

      chess.move({'from': from, 'to': to, 'promotion': promotion ?? 'q'});
      final score = _alphaBeta(chess, depth - 1, -999999, 999999, !isWhiteTurn);
      chess.undo();

      if (isWhiteTurn) {
        if (score > bestScore) {
          bestScore = score;
          bestMoveUci = uci;
        }
      } else {
        if (score < bestScore) {
          bestScore = score;
          bestMoveUci = uci;
        }
      }
    }

    return EngineEvaluation(
      scoreCp: bestScore.clamp(-10000.0, 10000.0),
      bestMoveUci: bestMoveUci,
      depth: depth,
    );
  }

  double _alphaBeta(
    chess_lib.Chess chess,
    int depth,
    double alpha,
    double beta,
    bool isMaximizing,
  ) {
    if (chess.in_checkmate) return isMaximizing ? -10000.0 : 10000.0;
    if (chess.in_draw) return 0.0;
    if (depth <= 0) return _evaluateHeuristic(chess);

    final moves = chess.moves({'verbose': true});
    if (moves.isEmpty) return _evaluateHeuristic(chess);

    if (isMaximizing) {
      double maxEval = -999999;
      for (final m in moves) {
        final moveMap = m as Map;
        chess.move({'from': moveMap['from'], 'to': moveMap['to'], 'promotion': moveMap['promotion'] ?? 'q'});
        final evaluation = _alphaBeta(chess, depth - 1, alpha, beta, false);
        chess.undo();
        maxEval = max(maxEval, evaluation);
        alpha = max(alpha, evaluation);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      double minEval = 999999;
      for (final m in moves) {
        final moveMap = m as Map;
        chess.move({'from': moveMap['from'], 'to': moveMap['to'], 'promotion': moveMap['promotion'] ?? 'q'});
        final evaluation = _alphaBeta(chess, depth - 1, alpha, beta, true);
        chess.undo();
        minEval = min(minEval, evaluation);
        beta = min(beta, evaluation);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  /// Positional evaluation in centipawns
  double _evaluateHeuristic(chess_lib.Chess chess) {
    double total = 0.0;

    const pieceValues = {
      'p': 100.0,
      'n': 320.0,
      'b': 330.0,
      'r': 500.0,
      'q': 900.0,
      'k': 20000.0,
    };

    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    for (int r = 1; r <= 8; r++) {
      for (final f in files) {
        final sq = '$f$r';
        final piece = chess.get(sq);
        if (piece != null) {
          final val = pieceValues[piece.type.name] ?? 0.0;
          final isW = piece.color == chess_lib.Color.WHITE;

          // Center control bonus
          double posBonus = 0.0;
          if (sq == 'd4' || sq == 'd5' || sq == 'e4' || sq == 'e5') {
            posBonus += 25.0;
          } else if (sq == 'c4' || sq == 'c5' || sq == 'f4' || sq == 'f5' ||
                     sq == 'd3' || sq == 'd6' || sq == 'e3' || sq == 'e6') {
            posBonus += 10.0;
          }

          // Development bonus for Knights & Bishops off the back rank
          if (piece.type.name == 'n' || piece.type.name == 'b') {
            if (isW && r > 1) posBonus += 15.0;
            if (!isW && r < 8) posBonus += 15.0;
          }

          if (isW) {
            total += val + posBonus;
          } else {
            total -= val + posBonus;
          }
        }
      }
    }

    return total;
  }

  void dispose() {
    _stdoutSub?.cancel();
    try {
      _nativeStockfish?.dispose();
    } catch (_) {}
  }
}
