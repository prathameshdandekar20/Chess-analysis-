import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../services/stockfish_engine_service.dart';
import '../../services/sound_service.dart';
import '../../services/analysis_engine.dart';
import '../theme/chess_theme.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/eval_bar_widget.dart';
import '../widgets/board_arrows_painter.dart';
import 'game_review_screen.dart';

class LiveAnalysisScreen extends StatefulWidget {
  const LiveAnalysisScreen({super.key});

  @override
  State<LiveAnalysisScreen> createState() => _LiveAnalysisScreenState();
}

class _LiveAnalysisScreenState extends State<LiveAnalysisScreen> {
  late chess_lib.Chess _game;
  bool _isFlipped = false;
  String? _selectedSquare;
  List<String> _legalDestinations = [];
  String? _lastFrom;
  String? _lastTo;

  // Stockfish evaluation state
  double _evalCp = 0.0;
  int? _mateIn;
  String _bestMoveUci = '';
  List<String> _pv = [];
  int _searchDepth = 12;
  bool _isAnalyzing = false;
  Timer? _debounceTimer;

  // Move history for review
  final List<String> _sanHistory = [];

  @override
  void initState() {
    super.initState();
    _game = chess_lib.Chess();
    _requestEngineEval();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _requestEngineEval() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () async {
      if (!mounted) return;
      setState(() => _isAnalyzing = true);

      final fen = _game.fen;
      final eval = await StockfishEngineService.instance.evaluatePosition(
        fen,
        depth: _searchDepth,
        moveTimeMs: 400,
      );

      if (!mounted || _game.fen != fen) return;

      setState(() {
        _evalCp = eval.scoreCp;
        _mateIn = eval.mateIn;
        _bestMoveUci = eval.bestMoveUci;
        _pv = eval.pv;
        _isAnalyzing = false;
      });
    });
  }

  void _onSquareTapped(String square) {
    if (_selectedSquare == null) {
      final piece = _game.get(square);
      if (piece != null && piece.color == _game.turn) {
        final moves = _game.moves({'square': square, 'verbose': true});
        setState(() {
          _selectedSquare = square;
          _legalDestinations = moves.map((m) => (m as Map)['to'] as String).toList();
        });
      }
    } else {
      if (square == _selectedSquare) {
        setState(() {
          _selectedSquare = null;
          _legalDestinations.clear();
        });
        return;
      }

      if (_legalDestinations.contains(square)) {
        _makeMove(_selectedSquare!, square);
      } else {
        final piece = _game.get(square);
        if (piece != null && piece.color == _game.turn) {
          final moves = _game.moves({'square': square, 'verbose': true});
          setState(() {
            _selectedSquare = square;
            _legalDestinations = moves.map((m) => (m as Map)['to'] as String).toList();
          });
        } else {
          setState(() {
            _selectedSquare = null;
            _legalDestinations.clear();
          });
        }
      }
    }
  }

  void _makeMove(String from, String to) {
    final legal = _game.moves({'verbose': true});
    Map? found;
    for (final m in legal) {
      final map = m as Map;
      if (map['from'] == from && map['to'] == to) {
        found = map;
        break;
      }
    }

    final success = _game.move({'from': from, 'to': to, 'promotion': 'q'});
    if (success && found != null) {
      final san = found['san'] as String? ?? '';
      final captured = found['captured'] != null;

      _sanHistory.add(san);
      if (_game.in_check) {
        SoundService.instance.playCheck();
      } else if (captured) {
        SoundService.instance.playCapture();
      } else {
        SoundService.instance.playMove();
      }

      setState(() {
        _lastFrom = from;
        _lastTo = to;
        _selectedSquare = null;
        _legalDestinations.clear();
      });

      _requestEngineEval();
    }
  }

  void _undoMove() {
    if (_sanHistory.isNotEmpty) {
      _game.undo();
      _sanHistory.removeLast();
      setState(() {
        _selectedSquare = null;
        _legalDestinations.clear();
        _lastFrom = null;
        _lastTo = null;
      });
      _requestEngineEval();
    }
  }

  void _resetBoard() {
    setState(() {
      _game = chess_lib.Chess();
      _sanHistory.clear();
      _selectedSquare = null;
      _legalDestinations.clear();
      _lastFrom = null;
      _lastTo = null;
    });
    _requestEngineEval();
  }

  void _launchReview() async {
    if (_sanHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Make some moves on the board first to review!')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          color: ChessTheme.surfaceCard,
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: ChessTheme.brandGreen),
                SizedBox(height: 16),
                Text('Running Stockfish Game Review...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    final reviewData = await AnalysisEngine.instance.reviewGame(
      sanMoves: List.from(_sanHistory),
      whitePlayer: 'White',
      blackPlayer: 'Black',
    );

    if (mounted) {
      Navigator.pop(context); // Close dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => GameReviewScreen(reviewData: reviewData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final arrows = <ArrowData>[];
    if (_bestMoveUci.length >= 4) {
      arrows.add(ArrowData(
        from: _bestMoveUci.substring(0, 2),
        to: _bestMoveUci.substring(2, 4),
        color: ChessTheme.brandGreen,
        width: 7.0,
      ));
    }

    return Scaffold(
      backgroundColor: ChessTheme.background,
      appBar: AppBar(
        title: const Text('Live Stockfish Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded),
            tooltip: 'Flip Board',
            onPressed: () => setState(() => _isFlipped = !_isFlipped),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Board',
            onPressed: _resetBoard,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Board & Eval Bar
              SizedBox(
                height: 350,
                child: Row(
                  children: [
                    EvalBarWidget(
                      evalCp: _evalCp,
                      mateIn: _mateIn,
                      isFlipped: _isFlipped,
                      height: 350,
                      width: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChessBoardWidget(
                        game: _game,
                        isFlipped: _isFlipped,
                        selectedSquare: _selectedSquare,
                        lastMoveFrom: _lastFrom,
                        lastMoveTo: _lastTo,
                        legalDestinations: _legalDestinations,
                        arrows: arrows,
                        onSquareTapped: _onSquareTapped,
                        onMoveMade: _makeMove,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 2. Engine Info Box (Stockfish Depth, Evaluation, Top Line)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ChessTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('⚡ Stockfish 16', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                            const SizedBox(width: 8),
                            if (_isAnalyzing)
                              const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: ChessTheme.brandGreen)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ChessTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _mateIn != null
                                ? (_mateIn! > 0 ? 'M${_mateIn!.abs()}' : '-M${_mateIn!.abs()}')
                                : '${(_evalCp / 100.0) >= 0 ? "+" : ""}${(_evalCp / 100.0).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Best Line: ${_pv.isNotEmpty ? _pv.take(6).join(" ") : (_bestMoveUci.isNotEmpty ? _bestMoveUci : "Calculating...")}',
                      style: const TextStyle(color: ChessTheme.brandGreenLight, fontSize: 12.5, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 3. Action Buttons (Takeback, Run Game Review)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _sanHistory.isNotEmpty ? _undoMove : null,
                      icon: const Icon(Icons.undo_rounded, size: 18),
                      label: const Text('Takeback'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _sanHistory.isNotEmpty ? _launchReview : null,
                      icon: const Icon(Icons.auto_graph_rounded, size: 18),
                      label: const Text('Review Game', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChessTheme.brandGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 4. Move history chips
              if (_sanHistory.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ChessTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: List.generate(_sanHistory.length, (idx) {
                      final isWhite = idx % 2 == 0;
                      final moveNum = (idx ~/ 2) + 1;
                      return Text(
                        '${isWhite ? "$moveNum. " : ""}${_sanHistory[idx]}',
                        style: TextStyle(
                          color: isWhite ? Colors.white : Colors.white70,
                          fontSize: 12,
                          fontWeight: isWhite ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
