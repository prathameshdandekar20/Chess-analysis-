import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../models/chess_move_eval.dart';
import '../../models/game_review_data.dart';
import '../../models/coach_profile.dart';
import '../../services/sound_service.dart';
import '../../services/coach_voice_service.dart';
import '../theme/chess_theme.dart';
import '../widgets/chess_board_widget.dart';
import '../widgets/eval_bar_widget.dart';
import '../widgets/coach_card_widget.dart';
import '../widgets/advantage_graph_widget.dart';
import '../widgets/move_history_list.dart';
import '../widgets/move_badge_widget.dart';
import '../widgets/board_arrows_painter.dart';

class GameReviewScreen extends StatefulWidget {
  final GameReviewData reviewData;

  const GameReviewScreen({
    super.key,
    required this.reviewData,
  });

  @override
  State<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends State<GameReviewScreen> {
  late chess_lib.Chess _boardGame;
  int _currentMoveIndex = -1; // -1 = start of game
  bool _isFlipped = false;
  bool _showBestMoveArrow = true;
  bool _isPlaying = false;
  Timer? _playTimer;
  CoachProfile _currentCoach = CoachProfile.presets[0];

  // Retry Mistake Puzzle Mode State
  bool _isRetryMode = false;
  String? _retrySelectedSquare;
  List<String> _retryLegalDestinations = [];
  bool? _retrySuccess; // true: correct, false: wrong

  @override
  void initState() {
    super.initState();
    _boardGame = chess_lib.Chess();
    if (widget.reviewData.moves.isNotEmpty) {
      // Start at move 0
      _selectMove(0);
    }
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    CoachVoiceService.instance.stop();
    super.dispose();
  }

  void _selectMove(int index) {
    if (index < -1 || index >= widget.reviewData.moves.length) return;

    setState(() {
      _currentMoveIndex = index;
      _isRetryMode = false;
      _retrySuccess = null;
      _retrySelectedSquare = null;
      _retryLegalDestinations.clear();

      if (index == -1) {
        _boardGame = chess_lib.Chess();
      } else {
        final move = widget.reviewData.moves[index];
        _boardGame = chess_lib.Chess();
        _boardGame.load(move.fenAfter);

        if (move.classification == MoveClassification.brilliant) {
          SoundService.instance.playBrilliant();
        } else if (move.classification == MoveClassification.blunder) {
          SoundService.instance.playBlunder();
        } else {
          SoundService.instance.playMove();
        }

        // Speak Coach Commentary in Voice
        final commentary = _currentCoach.generateCommentary(
          classification: move.classification,
          san: move.san,
          bestMoveSan: move.bestMoveSan,
          isWhite: move.isWhite,
          evalAfterCp: move.evalAfter,
          openingName: widget.reviewData.openingName,
          captured: false,
        );
        CoachVoiceService.instance.speakCommentary(
          commentary: commentary,
          personality: _currentCoach.personality,
        );
      }
    });
  }

  void _nextMove() {
    if (_currentMoveIndex < widget.reviewData.moves.length - 1) {
      _selectMove(_currentMoveIndex + 1);
    } else {
      _stopAutoPlay();
    }
  }

  void _previousMove() {
    if (_currentMoveIndex > 0) {
      _selectMove(_currentMoveIndex - 1);
    } else if (_currentMoveIndex == 0) {
      _selectMove(-1);
    }
  }

  void _toggleAutoPlay() {
    if (_isPlaying) {
      _stopAutoPlay();
    } else {
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    setState(() => _isPlaying = true);
    _playTimer?.cancel();
    _playTimer = Timer.periodic(const Duration(milliseconds: 1600), (timer) {
      if (_currentMoveIndex < widget.reviewData.moves.length - 1) {
        _nextMove();
      } else {
        _stopAutoPlay();
      }
    });
  }

  void _stopAutoPlay() {
    _playTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _startRetryMode() {
    if (_currentMoveIndex < 0) return;
    final move = widget.reviewData.moves[_currentMoveIndex];

    setState(() {
      _isRetryMode = true;
      _retrySuccess = null;
      _retrySelectedSquare = null;
      _retryLegalDestinations.clear();
      // Load position BEFORE the blunder
      _boardGame = chess_lib.Chess();
      _boardGame.load(move.fenBefore);
    });
  }

  void _handleSquareTapped(String square) {
    if (!_isRetryMode) return;

    if (_retrySelectedSquare == null) {
      final piece = _boardGame.get(square);
      if (piece != null && piece.color == _boardGame.turn) {
        final moves = _boardGame.moves({'square': square, 'verbose': true});
        setState(() {
          _retrySelectedSquare = square;
          _retryLegalDestinations = moves.map((m) => (m as Map)['to'] as String).toList();
        });
      }
    } else {
      if (square == _retrySelectedSquare) {
        setState(() {
          _retrySelectedSquare = null;
          _retryLegalDestinations.clear();
        });
        return;
      }

      if (_retryLegalDestinations.contains(square)) {
        _submitRetryMove(_retrySelectedSquare!, square);
      } else {
        final piece = _boardGame.get(square);
        if (piece != null && piece.color == _boardGame.turn) {
          final moves = _boardGame.moves({'square': square, 'verbose': true});
          setState(() {
            _retrySelectedSquare = square;
            _retryLegalDestinations = moves.map((m) => (m as Map)['to'] as String).toList();
          });
        } else {
          setState(() {
            _retrySelectedSquare = null;
            _retryLegalDestinations.clear();
          });
        }
      }
    }
  }

  void _submitRetryMove(String from, String to) {
    if (_currentMoveIndex < 0) return;
    final move = widget.reviewData.moves[_currentMoveIndex];
    final playedUci = '$from$to';

    final bestUciPrefix = move.bestMoveUci.length >= 4 ? move.bestMoveUci.substring(0, 4) : '';

    if (playedUci == bestUciPrefix) {
      _boardGame.move({'from': from, 'to': to, 'promotion': 'q'});
      SoundService.instance.playBrilliant();
      setState(() {
        _retrySuccess = true;
        _retrySelectedSquare = null;
        _retryLegalDestinations.clear();
      });
    } else {
      SoundService.instance.playBlunder();
      setState(() {
        _retrySuccess = false;
        _retrySelectedSquare = null;
        _retryLegalDestinations.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final moves = widget.reviewData.moves;
    final MoveEvaluation? currentMove =
        (_currentMoveIndex >= 0 && _currentMoveIndex < moves.length) ? moves[_currentMoveIndex] : null;

    final evalCp = currentMove?.evalAfter ?? 0.0;
    final mateIn = currentMove?.mateAfter;

    // Tactical arrows
    final arrows = <ArrowData>[];
    if (!_isRetryMode && currentMove != null) {
      // Best move arrow (green)
      if (_showBestMoveArrow && currentMove.bestMoveUci.length >= 4) {
        arrows.add(ArrowData(
          from: currentMove.bestMoveUci.substring(0, 2),
          to: currentMove.bestMoveUci.substring(2, 4),
          color: ChessTheme.brandGreen,
          width: 7.5,
        ));
      }

      // Played move arrow (red for blunder/mistake, cyan for brilliant)
      if (currentMove.classification.isNegative) {
        arrows.add(ArrowData(
          from: currentMove.fromSquare,
          to: currentMove.toSquare,
          color: currentMove.classification.color,
          width: 5.5,
        ));
      }
    }

    return Scaffold(
      backgroundColor: ChessTheme.background,
      appBar: AppBar(
        title: const Text('Game Review'),
        actions: [
          IconButton(
            icon: Icon(
              CoachVoiceService.instance.isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: CoachVoiceService.instance.isMuted ? Colors.white38 : _currentCoach.themeColor,
            ),
            tooltip: CoachVoiceService.instance.isMuted ? 'Unmute Coach Voice' : 'Mute Coach Voice',
            onPressed: () {
              setState(() {
                CoachVoiceService.instance.toggleMute();
              });
            },
          ),
          TextButton.icon(
            onPressed: _showCoachSelectionModal,
            icon: Text(_currentCoach.avatarEmoji, style: const TextStyle(fontSize: 18)),
            label: Text(
              _currentCoach.name,
              style: TextStyle(
                color: _currentCoach.themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Breakdown Summary',
            onPressed: () => _showBreakdownSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded),
            tooltip: 'Flip Board',
            onPressed: () => setState(() => _isFlipped = !_isFlipped),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Accuracy Summary Card (White vs Black CAPS)
              _buildAccuracyCard(),

              const SizedBox(height: 10),

              // 2. Interactive Chessboard with Eval Bar
              SizedBox(
                height: 340,
                child: Row(
                  children: [
                    // Vertical Eval Bar
                    EvalBarWidget(
                      evalCp: evalCp,
                      mateIn: mateIn,
                      isFlipped: _isFlipped,
                      height: 340,
                      width: 22,
                    ),
                    const SizedBox(width: 8),

                    // Chessboard
                    Expanded(
                      child: ChessBoardWidget(
                        game: _boardGame,
                        isFlipped: _isFlipped,
                        selectedSquare: _isRetryMode ? _retrySelectedSquare : null,
                        lastMoveFrom: currentMove?.fromSquare,
                        lastMoveTo: currentMove?.toSquare,
                        legalDestinations: _isRetryMode ? _retryLegalDestinations : const [],
                        arrows: arrows,
                        currentMoveBadge: !_isRetryMode ? currentMove?.classification : null,
                        badgeSquare: currentMove?.toSquare,
                        onSquareTapped: _handleSquareTapped,
                        onMoveMade: _isRetryMode ? _submitRetryMove : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 3. Retry Puzzle Banner or Virtual Coach Card
              if (_isRetryMode)
                _buildRetryBanner(currentMove)
              else
                CoachCardWidget(
                  currentMove: currentMove,
                  coach: _currentCoach,
                  onSelectCoach: _showCoachSelectionModal,
                  onRetryMistake: currentMove?.classification.isNegative == true ? _startRetryMode : null,
                  onToggleBestMoveArrow: () => setState(() => _showBestMoveArrow = !_showBestMoveArrow),
                  showBestMoveArrow: _showBestMoveArrow,
                ),

              const SizedBox(height: 8),

              // 4. Advantage Timeline Graph
              AdvantageGraphWidget(
                moves: moves,
                currentMoveIndex: _currentMoveIndex,
                onMoveSelected: _selectMove,
                height: 90,
              ),

              const SizedBox(height: 8),

              // 5. Playback Controls & Move List
              MoveHistoryListWidget(
                moves: moves,
                currentMoveIndex: _currentMoveIndex,
                onSelectMove: _selectMove,
                onFirst: () => _selectMove(-1),
                onPrevious: _previousMove,
                onNext: _nextMove,
                onLast: () => _selectMove(moves.length - 1),
                onFlip: () => setState(() => _isFlipped = !_isFlipped),
                isPlaying: _isPlaying,
                onTogglePlay: _toggleAutoPlay,
              ),

              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccuracyCard() {
    final rev = widget.reviewData;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ChessTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          // Player Accuracy Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // White Player
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black45),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rev.whitePlayer,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Elo ~${rev.whiteEstimatedElo}',
                        style: const TextStyle(color: ChessTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),

              // CAPS Accuracy Badges
              Row(
                children: [
                  _capsBadge(rev.whiteAccuracy, Colors.white, Colors.black),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('ACCURACY', style: TextStyle(color: ChessTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                  _capsBadge(rev.blackAccuracy, const Color(0xFF2C2A26), Colors.white),
                ],
              ),

              // Black Player
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        rev.blackPlayer,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Elo ~${rev.blackEstimatedElo}',
                        style: const TextStyle(color: ChessTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2A26),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),
          // Opening Title
          Text(
            '${rev.ecoCode}: ${rev.openingName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ChessTheme.brandGreenLight,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _capsBadge(double score, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        '${score.toStringAsFixed(1)}%',
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildRetryBanner(MoveEvaluation? move) {
    final isWhiteTurn = _boardGame.turn == chess_lib.Color.WHITE;

    Color bannerColor = ChessTheme.brandGreen;
    String statusText = 'Find the best move for ${isWhiteTurn ? "White" : "Black"}!';

    if (_retrySuccess == true) {
      bannerColor = ChessTheme.brandGreen;
      statusText = '🎉 Brilliant Find! That was Stockfish\'s top move!';
    } else if (_retrySuccess == false) {
      bannerColor = Colors.redAccent;
      statusText = '❌ Not quite. That wasn\'t the best move. Try again!';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _retrySuccess == true
                    ? Icons.check_circle_rounded
                    : (_retrySuccess == false ? Icons.cancel_rounded : Icons.psychology_rounded),
                color: bannerColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: bannerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isRetryMode = false),
                child: const Text('Back to Review', style: TextStyle(color: Colors.white70)),
              ),
              if (_retrySuccess == true)
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isRetryMode = false);
                    _nextMove();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChessTheme.brandGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Continue Review'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBreakdownSheet(BuildContext context) {
    final rev = widget.reviewData;
    showModalBottomSheet(
      context: context,
      backgroundColor: ChessTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Move Classification Breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: MoveClassification.values.map((c) {
                    final wCount = rev.countFor(true, c);
                    final bCount = rev.countFor(false, c);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$wCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Expanded(
                            child: MoveBadgeWidget(
                              classification: c,
                              size: MoveBadgeSize.regular,
                              showLabel: true,
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$bCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCoachSelectionModal() {
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.psychology_outlined, color: ChessTheme.brandGreen),
                  SizedBox(width: 8),
                  Text(
                    'Choose Your Game Review Coach',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Each coach delivers personalized commentary with their own unique style and advice.',
                style: TextStyle(color: ChessTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: CoachProfile.presets.length,
                  itemBuilder: (context, idx) {
                    final coach = CoachProfile.presets[idx];
                    final isSelected = coach.id == _currentCoach.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? coach.themeColor.withOpacity(0.12)
                            : ChessTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? coach.themeColor : Colors.white.withOpacity(0.06),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: coach.themeColor.withOpacity(0.2),
                          child: Text(coach.avatarEmoji, style: const TextStyle(fontSize: 22)),
                        ),
                        title: Row(
                          children: [
                            Text(
                              coach.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? coach.themeColor : Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isSelected)
                              Icon(Icons.check_circle, size: 16, color: coach.themeColor),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              coach.title,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                            ),
                            Text(
                              coach.tagline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: ChessTheme.textMuted),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() => _currentCoach = coach);
                          Navigator.pop(ctx);
                        },
                      ),
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
