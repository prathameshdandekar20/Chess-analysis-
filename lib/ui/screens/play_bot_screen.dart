import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../models/bot_profile.dart';
import '../../services/stockfish_engine_service.dart';
import '../../services/sound_service.dart';
import '../../services/analysis_engine.dart';
import '../theme/chess_theme.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/eval_bar_widget.dart';
import 'game_review_screen.dart';

class PlayBotScreen extends StatefulWidget {
  const PlayBotScreen({super.key});

  @override
  State<PlayBotScreen> createState() => _PlayBotScreenState();
}

class _PlayBotScreenState extends State<PlayBotScreen> {
  late chess_lib.Chess _game;
  BotProfile _selectedBot = BotProfile.presets[2]; // Nelson default
  bool _playerIsWhite = true;
  bool _showEvalBar = true;

  String? _selectedSquare;
  List<String> _legalDestinations = [];
  String? _lastFrom;
  String? _lastTo;

  bool _isBotThinking = false;
  double _evalCp = 0.0;
  int? _mateIn;

  final List<String> _sanHistory = [];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      _game = chess_lib.Chess();
      _sanHistory.clear();
      _selectedSquare = null;
      _legalDestinations.clear();
      _lastFrom = null;
      _lastTo = null;
      _evalCp = 0.0;
      _mateIn = null;
      _isBotThinking = false;
    });

    if (!_playerIsWhite) {
      _triggerBotMove();
    }
  }

  void _onSquareTapped(String square) {
    if (_isBotThinking) return;
    if (_game.game_over) return;

    final isWhiteTurn = _game.turn == chess_lib.Color.WHITE;
    if (isWhiteTurn != _playerIsWhite) return; // Not player's turn

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
        _makePlayerMove(_selectedSquare!, square);
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

  void _makePlayerMove(String from, String to) {
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

      _checkGameOver();

      if (!_game.game_over) {
        _triggerBotMove();
      }
    }
  }

  void _triggerBotMove() async {
    setState(() => _isBotThinking = true);

    // Realistic bot think delay
    await Future.delayed(const Duration(milliseconds: 650));

    final bestMoveUci = await StockfishEngineService.instance.getBestMove(
      _game.fen,
      skillLevel: _selectedBot.skillLevel,
      depth: _selectedBot.searchDepth,
      blunderChance: _selectedBot.blunderChance,
    );

    if (!mounted || _game.game_over) {
      setState(() => _isBotThinking = false);
      return;
    }

    if (bestMoveUci != null && bestMoveUci.length >= 4) {
      final from = bestMoveUci.substring(0, 2);
      final to = bestMoveUci.substring(2, 4);
      final prom = bestMoveUci.length > 4 ? bestMoveUci.substring(4, 5) : 'q';

      final legal = _game.moves({'verbose': true});
      Map? found;
      for (final m in legal) {
        final map = m as Map;
        if (map['from'] == from && map['to'] == to) {
          found = map;
          break;
        }
      }

      final success = _game.move({'from': from, 'to': to, 'promotion': prom});
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
          _isBotThinking = false;
        });

        _checkGameOver();
      } else {
        setState(() => _isBotThinking = false);
      }
    } else {
      setState(() => _isBotThinking = false);
    }
  }

  void _checkGameOver() {
    if (_game.game_over) {
      String title = 'Game Over';
      String msg = 'Game ended.';

      if (_game.in_checkmate) {
        final winnerIsWhite = _game.turn == chess_lib.Color.BLACK;
        if (winnerIsWhite == _playerIsWhite) {
          title = 'Victory! 🏆';
          msg = 'Checkmate! You defeated ${_selectedBot.name}!';
        } else {
          title = 'Defeat 💔';
          msg = 'Checkmate! ${_selectedBot.name} won the match.';
        }
      } else if (_game.in_draw) {
        title = 'Draw 🤝';
        msg = 'The game ended in a draw.';
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ChessTheme.surfaceCard,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _startNewGame();
              },
              child: const Text('New Game'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _launchReview();
              },
              icon: const Icon(Icons.auto_graph_rounded),
              label: const Text('Review Game'),
              style: ElevatedButton.styleFrom(backgroundColor: ChessTheme.brandGreen),
            ),
          ],
        ),
      );
    }
  }

  void _launchReview() async {
    if (_sanHistory.isEmpty) return;

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
                Text('Analyzing Game with Stockfish...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    final reviewData = await AnalysisEngine.instance.reviewGame(
      sanMoves: List.from(_sanHistory),
      whitePlayer: _playerIsWhite ? 'You' : _selectedBot.name,
      blackPlayer: _playerIsWhite ? _selectedBot.name : 'You',
    );

    if (mounted) {
      Navigator.pop(context);
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
    final isFlipped = !_playerIsWhite;

    return Scaffold(
      backgroundColor: ChessTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {},
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: ChessTheme.brandGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 6),
            const Text(
              'Chess.com',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22),
            tooltip: 'Search',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.people_outline_rounded),
            tooltip: 'Select Bot Personality',
            onPressed: _showBotSelectionDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Move Strip at top (e.g. 1. d4 d5  2. e4 dxe4  3. Nc3)
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.black.withOpacity(0.2),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: (_sanHistory.length / 2).ceil().clamp(1, 999),
                itemBuilder: (context, idx) {
                  final moveNum = idx + 1;
                  final wIdx = idx * 2;
                  final bIdx = wIdx + 1;
                  final wSan = wIdx < _sanHistory.length ? _sanHistory[wIdx] : (idx == 0 ? 'd4' : '');
                  final bSan = bIdx < _sanHistory.length ? _sanHistory[bIdx] : (idx == 0 ? 'd5' : '');

                  return Padding(
                    padding: const EdgeInsets.only(right: 14.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$moveNum.', style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Text(wSan, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 6),
                        Text(bSan, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Opponent Player Card (Top)
                    _buildPlayerCard(
                      name: _selectedBot.name,
                      subtitle: _selectedBot.subtitle,
                      avatar: _selectedBot.avatarEmoji,
                      elo: _selectedBot.elo,
                      isThinking: _isBotThinking,
                      isTop: true,
                    ),

                    const SizedBox(height: 6),

                    // 2. Interactive Board + Optional Eval Bar
                    SizedBox(
                      height: 356,
                      child: Row(
                        children: [
                          if (_showEvalBar) ...[
                            EvalBarWidget(
                              evalCp: _evalCp,
                              mateIn: _mateIn,
                              isFlipped: isFlipped,
                              height: 356,
                              width: 18,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: ChessBoardWidget(
                              game: _game,
                              isFlipped: isFlipped,
                              selectedSquare: _selectedSquare,
                              lastMoveFrom: _lastFrom,
                              lastMoveTo: _lastTo,
                              legalDestinations: _legalDestinations,
                              onSquareTapped: _onSquareTapped,
                              onMoveMade: _makePlayerMove,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 3. User Player Card (Bottom)
                    _buildPlayerCard(
                      name: 'You',
                      subtitle: _playerIsWhite ? 'Playing as White' : 'Playing as Black',
                      avatar: '♟️',
                      elo: 1500,
                      isThinking: !_isBotThinking && !_game.game_over && ((_game.turn == chess_lib.Color.WHITE) == _playerIsWhite),
                      isTop: false,
                    ),

                    const SizedBox(height: 10),

                    // 4. Chess.com Mobile Bottom Actions Bar (Options, Big Green Star, Back, Forward)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Options
                          InkWell(
                            onTap: _showBotSelectionDialog,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.format_list_bulleted_rounded, color: Colors.white70, size: 22),
                                SizedBox(height: 2),
                                Text('Options', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),

                          // Big Green Star Button (Review / Best Move)
                          GestureDetector(
                            onTap: _sanHistory.isNotEmpty ? _launchReview : null,
                            child: Container(
                              width: 58,
                              height: 44,
                              decoration: BoxDecoration(
                                color: ChessTheme.brandGreen,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: ChessTheme.brandGreen.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.star_rounded, color: Colors.white, size: 28),
                              ),
                            ),
                          ),

                          // Back <
                          InkWell(
                            onTap: _sanHistory.isNotEmpty ? () {
                              _game.undo();
                              if (_sanHistory.isNotEmpty) _sanHistory.removeLast();
                              setState(() {});
                            } : null,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chevron_left_rounded, color: Colors.white70, size: 24),
                                SizedBox(height: 2),
                                Text('Back', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ),

                          // Forward >
                          InkWell(
                            onTap: null,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 24),
                                SizedBox(height: 2),
                                Text('Forward', style: TextStyle(color: Colors.white30, fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required String name,
    required String subtitle,
    required String avatar,
    required int elo,
    required bool isThinking,
    required bool isTop,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Avatar + Name + Rating change
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTop ? const Color(0xFF2C241D) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Center(
                  child: Text(
                    avatar,
                    style: TextStyle(
                      fontSize: 22,
                      color: isTop ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      Text('($elo)', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isThinking ? (isTop ? 'Bot is thinking...' : 'Your turn...') : subtitle,
                    style: TextStyle(
                      color: isThinking ? ChessTheme.brandGreenLight : Colors.white54,
                      fontSize: 11,
                      fontWeight: isThinking ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Active turn indicator pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isThinking ? ChessTheme.brandGreen.withOpacity(0.2) : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isThinking ? ChessTheme.brandGreen : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isThinking) ...[
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ChessTheme.brandGreen),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  isThinking ? 'Thinking' : (isTop ? 'Waiting' : 'Your Turn'),
                  style: TextStyle(
                    color: isThinking ? ChessTheme.brandGreenLight : Colors.white60,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBotSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ChessTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose Bot Personality', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: BotProfile.presets.length,
                  itemBuilder: (context, idx) {
                    final bot = BotProfile.presets[idx];
                    final isSelected = bot.id == _selectedBot.id;

                    return ListTile(
                      leading: Text(bot.avatarEmoji, style: const TextStyle(fontSize: 26)),
                      title: Text('${bot.name} (${bot.elo})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(bot.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: ChessTheme.brandGreen) : null,
                      onTap: () {
                        setState(() => _selectedBot = bot);
                        Navigator.pop(ctx);
                        _startNewGame();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
