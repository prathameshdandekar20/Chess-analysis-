import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:stockfish_chess_engine/stockfish_chess_engine.dart';
import 'package:stockfish_chess_engine/stockfish_chess_engine_state.dart';
import 'package:chess/chess.dart' as chess_lib;

class EngineEvaluation {
  final double scoreCp; // Centipawns from White's perspective (+100 = +1.0)
  final int? mateIn; // Positive: White wins in X moves; Negative: Black wins; 0: Already checkmate
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

  /// Evaluates win percentage from White's perspective using Kenneth Regan / CAPS sigmoid model
  double get whiteWinChance {
    if (mateIn != null) {
      if (mateIn == 0) {
        return scoreCp > 0 ? 100.0 : 0.0;
      }
      return mateIn! > 0 ? 100.0 : 0.0;
    }
    // Exact Lichess/Kenneth Regan model: 50 + 50 * (2 / (1 + exp(-0.00368208 * scoreCp)) - 1)
    return (50.0 + 50.0 * (2.0 / (1.0 + exp(-0.00368208 * scoreCp)) - 1.0)).clamp(0.0, 100.0);
  }
}

/// Service managing real Stockfish UCI communication and high-speed rule-based mate detection
class StockfishEngineService {
  static final StockfishEngineService instance = StockfishEngineService._internal();

  StockfishEngineService._internal();

  Stockfish? _nativeStockfish;
  bool _isNativeReady = false;
  bool _initAttempted = false;

  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get whenReady async {
    if (!_initAttempted) {
      unawaited(init());
    }
    try {
      await _readyCompleter.future.timeout(const Duration(milliseconds: 1200), onTimeout: () {});
    } catch (_) {}
  }

  bool get isUsingNativeEngine => _isNativeReady;

  // Queue to serialize commands sent to the native UCI engine
  Future<void> _uciLock = Future.value();

  /// Initializes Stockfish engine
  Future<void> init() async {
    if (_initAttempted) return;
    _initAttempted = true;

    try {
      debugPrint('[StockfishService] Initializing Stockfish engine...');
      _nativeStockfish = Stockfish();

      if (_nativeStockfish?.state.value == StockfishState.ready) {
        _isNativeReady = true;
        _sendUciSetup();
        if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      } else {
        _nativeStockfish?.state.addListener(() {
          if (_nativeStockfish?.state.value == StockfishState.ready && !_isNativeReady) {
            _isNativeReady = true;
            _sendUciSetup();
            if (!_readyCompleter.isCompleted) _readyCompleter.complete();
            debugPrint('[StockfishService] Native Stockfish engine ready!');
          }
        });
      }

      // Max timeout for native isolate initialization
      Timer(const Duration(milliseconds: 2500), () {
        if (!_readyCompleter.isCompleted) {
          _readyCompleter.complete();
        }
      });
    } catch (e) {
      debugPrint('[StockfishService] Native Stockfish init failed ($e). Using fallback engine.');
      _isNativeReady = false;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }
  }

  void _sendUciSetup() {
    try {
      _nativeStockfish?.stdin = 'uci';
      _nativeStockfish?.stdin = 'setoption name Threads value 2';
      _nativeStockfish?.stdin = 'setoption name Hash value 16';
      _nativeStockfish?.stdin = 'isready';
    } catch (_) {}
  }

  /// Evaluates a position given by FEN.
  /// Evaluates a position given by FEN.
  /// Detects forced mates (M1, M2, M3, M4...) instantly or via deep Stockfish/Alpha-Beta search.
  Future<EngineEvaluation> evaluatePosition(
    String fen, {
    int depth = 14,
    int moveTimeMs = 500,
  }) async {
    // 1. FAST RULE-BASED CHECK: Detect terminal states, instant Mate-in-1, and forced Mate-in-2
    final fastCheck = _checkImmediateMateOrTerminal(fen);
    if (fastCheck != null) {
      return fastCheck;
    }

    await whenReady;

    if (_isNativeReady && _nativeStockfish != null) {
      try {
        return await _enqueueUci(() => _evaluateWithNativeStockfish(fen, depth: depth, moveTimeMs: moveTimeMs));
      } catch (e) {
        debugPrint('[StockfishService] Native eval error ($e), falling back to local engine');
      }
    }

    return evaluateLocal(fen, depth: 2);
  }

  /// Checks if the board is already checkmate/stalemate or has an IMMEDIATE Mate-in-1 or forced Mate-in-2
  EngineEvaluation? _checkImmediateMateOrTerminal(String fen) {
    try {
      final chess = chess_lib.Chess();
      if (!chess.load(fen)) return null;

      final isWhiteTurn = chess.turn == chess_lib.Color.WHITE;

      // Already in checkmate
      if (chess.in_checkmate) {
        return EngineEvaluation(
          scoreCp: isWhiteTurn ? -10000.0 : 10000.0,
          mateIn: 0,
          bestMoveUci: '',
          depth: 1,
        );
      }

      // In stalemate / draw
      if (chess.in_draw) {
        return const EngineEvaluation(
          scoreCp: 0.0,
          mateIn: null,
          bestMoveUci: '',
          depth: 1,
        );
      }

      // 1. Scan all legal moves to see if ANY move immediately delivers checkmate (Mate in 1)
      final legalMoves = chess.moves({'verbose': true});
      for (final m in legalMoves) {
        final map = m as Map;
        final from = map['from'] as String;
        final to = map['to'] as String;
        final prom = map['promotion'] as String?;
        final uci = '$from$to${prom ?? ''}';

        chess.move({'from': from, 'to': to, 'promotion': prom ?? 'q'});
        final deliversMate = chess.in_checkmate;
        chess.undo();

        if (deliversMate) {
          // Instant Mate-in-1 found!
          return EngineEvaluation(
            scoreCp: isWhiteTurn ? 10000.0 : -10000.0,
            mateIn: isWhiteTurn ? 1 : -1,
            bestMoveUci: uci,
            pv: [uci],
            depth: 1,
          );
        }
      }

      // 2. Scan checking candidate moves for guaranteed forced Mate in 2 (M2)
      final checkingMoves = legalMoves.where((m) {
        final map = m as Map;
        final san = map['san'] as String? ?? '';
        return san.contains('+') || san.contains('#');
      }).toList();

      for (final m in checkingMoves) {
        final map = m as Map;
        final from = map['from'] as String;
        final to = map['to'] as String;
        final prom = map['promotion'] as String?;
        final uci = '$from$to${prom ?? ''}';

        chess.move({'from': from, 'to': to, 'promotion': prom ?? 'q'});
        final oppReplies = chess.moves({'verbose': true});

        if (oppReplies.isNotEmpty && oppReplies.length <= 4) {
          bool allRepliesMated = true;
          for (final oppM in oppReplies) {
            final oppMap = oppM as Map;
            chess.move({
              'from': oppMap['from'] as String,
              'to': oppMap['to'] as String,
              'promotion': (oppMap['promotion'] as String?) ?? 'q',
            });

            // Check if any checking reply delivers checkmate
            final playerReplies = chess.moves({'verbose': true});
            final candidateMates = playerReplies.where((pm) {
              final san = (pm as Map)['san'] as String? ?? '';
              return san.contains('+') || san.contains('#');
            });
            bool hasMateReply = false;
            for (final pm in candidateMates) {
              final pMap = pm as Map;
              chess.move({
                'from': pMap['from'] as String,
                'to': pMap['to'] as String,
                'promotion': (pMap['promotion'] as String?) ?? 'q',
              });
              if (chess.in_checkmate) {
                hasMateReply = true;
                chess.undo();
                break;
              }
              chess.undo();
            }

            chess.undo(); // undo opponent move

            if (!hasMateReply) {
              allRepliesMated = false;
              break;
            }
          }

          chess.undo(); // undo player move

          if (allRepliesMated) {
            // Guaranteed forced Mate-in-2 found!
            return EngineEvaluation(
              scoreCp: isWhiteTurn ? 10000.0 : -10000.0,
              mateIn: isWhiteTurn ? 2 : -2,
              bestMoveUci: uci,
              pv: [uci],
              depth: 3,
            );
          }
        } else {
          chess.undo();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Serializes UCI commands so parallel queries never cross-talk
  Future<T> _enqueueUci<T>(Future<T> Function() task) async {
    final prev = _uciLock;
    final completer = Completer<void>();
    _uciLock = completer.future;
    try {
      await prev;
      return await task();
    } finally {
      completer.complete();
    }
  }

  /// Evaluates position with native C++ Stockfish over UCI
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

    final isWhiteTurn = fen.split(' ')[1] == 'w';

    late StreamSubscription<String> sub;
    Timer? timeoutTimer;

    sub = _nativeStockfish!.stdout.listen((line) {
      if (line.startsWith('info ') && line.contains('score ')) {
        // Only evaluate primary variation (multipv 1 or single-line search)
        if (line.contains('multipv ') && !line.contains('multipv 1 ')) {
          return;
        }

        final tokens = line.split(' ');
        for (int i = 0; i < tokens.length; i++) {
          if (tokens[i] == 'mate' && i + 1 < tokens.length) {
            final parsed = int.tryParse(tokens[i + 1]);
            if (parsed != null) {
              currentMate = isWhiteTurn ? parsed : -parsed;
              currentCp = currentMate! > 0 ? 10000.0 : -10000.0;
            }
          } else if (tokens[i] == 'cp' && i + 1 < tokens.length) {
            final parsed = double.tryParse(tokens[i + 1]);
            if (parsed != null) {
              currentCp = isWhiteTurn ? parsed : -parsed;
              if (!line.contains('lowerbound') && !line.contains('upperbound')) {
                currentMate = null;
              }
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

    timeoutTimer = Timer(Duration(milliseconds: moveTimeMs + 800), () {
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

  /// Built-in Alpha-Beta evaluation engine with precise mate-distance calculation
  EngineEvaluation evaluateLocal(String fen, {int depth = 3}) {
    // Instant terminal/mate-in-1 check
    final fast = _checkImmediateMateOrTerminal(fen);
    if (fast != null) return fast;

    final chess = chess_lib.Chess();
    if (!chess.load(fen)) {
      return const EngineEvaluation(scoreCp: 0, bestMoveUci: '');
    }

    final isWhiteTurn = chess.turn == chess_lib.Color.WHITE;
    final moves = chess.moves({'verbose': true});
    if (moves.isEmpty) {
      return const EngineEvaluation(scoreCp: 0, bestMoveUci: '');
    }

    String bestMoveUci = '';
    double bestScore = isWhiteTurn ? -999999.0 : 999999.0;
    int? foundMateIn;
    double alpha = -999999.0;
    double beta = 999999.0;

    for (final m in moves) {
      final moveMap = m as Map;
      final from = moveMap['from'] as String;
      final to = moveMap['to'] as String;
      final promotion = moveMap['promotion'] as String?;
      final uci = '$from$to${promotion ?? ''}';

      chess.move({'from': from, 'to': to, 'promotion': promotion ?? 'q'});
      final score = _alphaBeta(chess, depth - 1, alpha, beta, !isWhiteTurn, 1);
      chess.undo();

      if (isWhiteTurn) {
        if (score > bestScore) {
          bestScore = score;
          bestMoveUci = uci;
        }
        alpha = max(alpha, bestScore);
      } else {
        if (score < bestScore) {
          bestScore = score;
          bestMoveUci = uci;
        }
        beta = min(beta, bestScore);
      }
      if (beta <= alpha) break;
    }

    // Check if score represents a forced checkmate
    if (bestScore.abs() > 25000.0) {
      final ply = (30000.0 - bestScore.abs()).round();
      final mateMoves = max(1, (ply / 2).ceil());
      foundMateIn = bestScore > 0 ? mateMoves : -mateMoves;
    }

    return EngineEvaluation(
      scoreCp: bestScore.clamp(-10000.0, 10000.0),
      mateIn: foundMateIn,
      bestMoveUci: bestMoveUci,
      pv: bestMoveUci.isNotEmpty ? [bestMoveUci] : [],
      depth: depth,
    );
  }

  double _alphaBeta(
    chess_lib.Chess chess,
    int depth,
    double alpha,
    double beta,
    bool isMaximizing,
    int ply,
  ) {
    if (chess.in_checkmate) {
      // Shorter mates score higher/lower so fastest mate is always preferred
      return isMaximizing ? (-30000.0 + ply) : (30000.0 - ply);
    }
    if (chess.in_draw) return 0.0;
    if (depth <= 0) return _evaluateHeuristic(chess);

    final moves = chess.moves({'verbose': true});
    if (moves.isEmpty) return _evaluateHeuristic(chess);

    if (isMaximizing) {
      double maxEval = -999999.0;
      for (final m in moves) {
        final moveMap = m as Map;
        final from = moveMap['from'] as String;
        final to = moveMap['to'] as String;
        final promotion = moveMap['promotion'] as String?;

        chess.move({'from': from, 'to': to, 'promotion': promotion ?? 'q'});
        final evaluation = _alphaBeta(chess, depth - 1, alpha, beta, false, ply + 1);
        chess.undo();

        maxEval = max(maxEval, evaluation);
        alpha = max(alpha, evaluation);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      double minEval = 999999.0;
      for (final m in moves) {
        final moveMap = m as Map;
        final from = moveMap['from'] as String;
        final to = moveMap['to'] as String;
        final promotion = moveMap['promotion'] as String?;

        chess.move({'from': from, 'to': to, 'promotion': promotion ?? 'q'});
        final evaluation = _alphaBeta(chess, depth - 1, alpha, beta, true, ply + 1);
        chess.undo();

        minEval = min(minEval, evaluation);
        beta = min(beta, evaluation);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  double _evaluateHeuristic(chess_lib.Chess chess) {
    double total = 0.0;

    const pieceValues = {
      'p': 100.0,
      'n': 320.0,
      'b': 330.0,
      'r': 500.0,
      'q': 900.0,
      'k': 0.0, // Kings don't have relative piece value difference
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

          // Development bonus
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
    try {
      _nativeStockfish?.dispose();
    } catch (_) {}
  }
}
