import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../theme/chess_theme.dart';
import '../../models/chess_move_eval.dart';
import 'chess_piece_svg.dart';
import 'board_arrows_painter.dart';
import 'move_badge_widget.dart';

class ChessBoardWidget extends StatefulWidget {
  final chess_lib.Chess game;
  final bool isFlipped;
  final String? selectedSquare;
  final String? lastMoveFrom;
  final String? lastMoveTo;
  final List<String> legalDestinations;
  final List<ArrowData> arrows;
  final MoveClassification? currentMoveBadge;
  final String? badgeSquare;
  final Function(String square)? onSquareTapped;
  final Function(String from, String to)? onMoveMade;

  const ChessBoardWidget({
    super.key,
    required this.game,
    this.isFlipped = false,
    this.selectedSquare,
    this.lastMoveFrom,
    this.lastMoveTo,
    this.legalDestinations = const [],
    this.arrows = const [],
    this.currentMoveBadge,
    this.badgeSquare,
    this.onSquareTapped,
    this.onMoveMade,
  });

  @override
  State<ChessBoardWidget> createState() => _ChessBoardWidgetState();
}

class _ChessBoardWidgetState extends State<ChessBoardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _moveAnimController;
  late Animation<double> _moveCurvedAnim;

  // Animation tracking
  bool _isAnimating = false;
  String? _animFrom;
  String? _animTo;
  chess_lib.Piece? _animPiece;
  Offset _animStartPos = Offset.zero;
  Offset _animEndPos = Offset.zero;

  // Castling secondary animation (for the moving Rook)
  chess_lib.Piece? _castleRookPiece;
  Offset _castleRookStart = Offset.zero;
  Offset _castleRookEnd = Offset.zero;
  String? _castleRookTo;

  // Hover target for drag-and-drop feedback
  String? _hoverTargetSquare;

  @override
  void initState() {
    super.initState();
    _moveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _moveCurvedAnim = CurvedAnimation(
      parent: _moveAnimController,
      curve: Curves.easeOutCubic,
    );

    _moveAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _animPiece = null;
            _animFrom = null;
            _animTo = null;
            _castleRookPiece = null;
            _castleRookTo = null;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(ChessBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastMoveTo != null &&
        widget.lastMoveFrom != null &&
        (widget.lastMoveTo != oldWidget.lastMoveTo ||
            widget.lastMoveFrom != oldWidget.lastMoveFrom)) {
      _triggerMoveAnimation(
        from: widget.lastMoveFrom!,
        to: widget.lastMoveTo!,
      );
    }
  }

  void _triggerMoveAnimation({required String from, required String to}) {
    final movedPiece = widget.game.get(to);
    if (movedPiece == null) return;

    _animPiece = movedPiece;
    _animFrom = from;
    _animTo = to;
    _castleRookPiece = null;
    _castleRookTo = null;

    // Detect Castling to also animate the accompanying Rook
    if (movedPiece.type == chess_lib.PieceType.KING) {
      if (from == 'e1' && to == 'g1') {
        _castleRookPiece = widget.game.get('f1');
        _castleRookTo = 'f1';
      } else if (from == 'e1' && to == 'c1') {
        _castleRookPiece = widget.game.get('d1');
        _castleRookTo = 'd1';
      } else if (from == 'e8' && to == 'g8') {
        _castleRookPiece = widget.game.get('f8');
        _castleRookTo = 'f8';
      } else if (from == 'e8' && to == 'c8') {
        _castleRookPiece = widget.game.get('d8');
        _castleRookTo = 'd8';
      }
    }

    _isAnimating = true;
    _moveAnimController.reset();
    _moveAnimController.forward();
  }

  Offset _getSquarePixelOffset(String square, double squareSize) {
    if (square.length < 2) return Offset.zero;
    final file = square[0].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.tryParse(square[1]) ?? 1;

    final col = widget.isFlipped ? (7 - file) : file;
    final row = widget.isFlipped ? (rank - 1) : (8 - rank);

    return Offset(col * squareSize, row * squareSize);
  }

  @override
  void dispose() {
    _moveAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final squareSize = boardSize / 8.0;

        // Update animation start/end coordinates with actual squareSize
        if (_isAnimating && _animFrom != null && _animTo != null) {
          _animStartPos = _getSquarePixelOffset(_animFrom!, squareSize);
          _animEndPos = _getSquarePixelOffset(_animTo!, squareSize);

          if (_castleRookPiece != null && _castleRookTo != null) {
            final rookFrom = _castleRookTo == 'f1'
                ? 'h1'
                : (_castleRookTo == 'd1'
                    ? 'a1'
                    : (_castleRookTo == 'f8' ? 'h8' : 'a8'));
            _castleRookStart = _getSquarePixelOffset(rookFrom, squareSize);
            _castleRookEnd = _getSquarePixelOffset(_castleRookTo!, squareSize);
          }
        }

        return Center(
          child: Container(
            width: boardSize,
            height: boardSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 1. Board Squares & Static Pieces
                Column(
                  children: List.generate(8, (rIndex) {
                    final rank = widget.isFlipped ? (rIndex + 1) : (8 - rIndex);
                    return Row(
                      children: List.generate(8, (fIndex) {
                        final file = widget.isFlipped ? (7 - fIndex) : fIndex;
                        final fileChar =
                            String.fromCharCode('a'.codeUnitAt(0) + file);
                        final square = '$fileChar$rank';

                        final isLight = (file + rank) % 2 != 0;
                        return _buildSquare(
                          context,
                          square: square,
                          fileChar: fileChar,
                          rank: rank,
                          rIndex: rIndex,
                          fIndex: fIndex,
                          isLight: isLight,
                          size: squareSize,
                        );
                      }),
                    );
                  }),
                ),

                // 2. Tactical Arrows Painter
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      size: Size(boardSize, boardSize),
                      painter: BoardArrowsPainter(
                        arrows: widget.arrows,
                        isFlipped: widget.isFlipped,
                      ),
                    ),
                  ),
                ),

                // 3. Smooth Moving Piece Animated Overlay (Glides with ease-out cubic curve)
                if (_isAnimating && _animPiece != null)
                  AnimatedBuilder(
                    animation: _moveCurvedAnim,
                    builder: (context, child) {
                      final pos = Offset.lerp(
                        _animStartPos,
                        _animEndPos,
                        _moveCurvedAnim.value,
                      )!;
                      return Positioned(
                        left: pos.dx,
                        top: pos.dy,
                        width: squareSize,
                        height: squareSize,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ChessPieceSvg(
                                pieceType: _animPiece!.type.name,
                                isWhite: _animPiece!.color == chess_lib.Color.WHITE,
                                size: squareSize,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // 4. Smooth Castling Rook Animated Overlay
                if (_isAnimating && _castleRookPiece != null)
                  AnimatedBuilder(
                    animation: _moveCurvedAnim,
                    builder: (context, child) {
                      final pos = Offset.lerp(
                        _castleRookStart,
                        _castleRookEnd,
                        _moveCurvedAnim.value,
                      )!;
                      return Positioned(
                        left: pos.dx,
                        top: pos.dy,
                        width: squareSize,
                        height: squareSize,
                        child: IgnorePointer(
                          child: Center(
                            child: ChessPieceSvg(
                              pieceType: _castleRookPiece!.type.name,
                              isWhite:
                                  _castleRookPiece!.color == chess_lib.Color.WHITE,
                              size: squareSize,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                // 5. Floating Move Badge on Destination Square
                if (widget.currentMoveBadge != null && widget.badgeSquare != null)
                  _buildFloatingBadge(widget.badgeSquare!, squareSize),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSquare(
    BuildContext context, {
    required String square,
    required String fileChar,
    required int rank,
    required int rIndex,
    required int fIndex,
    required bool isLight,
    required double size,
  }) {
    final isSelected = square == widget.selectedSquare;
    final isLastMove =
        square == widget.lastMoveFrom || square == widget.lastMoveTo;
    final isLegalTarget = widget.legalDestinations.contains(square);
    final isHovered = square == _hoverTargetSquare;

    // Check indicator
    bool isCheck = false;
    final piece = widget.game.get(square);
    if (piece != null && piece.type == chess_lib.PieceType.KING) {
      if (widget.game.in_check && widget.game.turn == piece.color) {
        isCheck = true;
      }
    }

    Color squareColor =
        isLight ? ChessTheme.boardLightSquare : ChessTheme.boardDarkSquare;
    if (isSelected) {
      squareColor = ChessTheme.selectedSquareHighlight;
    } else if (isLastMove) {
      squareColor = Color.alphaBlend(ChessTheme.lastMoveHighlight, squareColor);
    }

    if (isHovered && isLegalTarget) {
      squareColor = Color.alphaBlend(
        Colors.greenAccent.withOpacity(0.35),
        squareColor,
      );
    }

    // While animating, hide piece on destination square so sliding piece overlay represents it
    final hidePieceForAnimation = _isAnimating &&
        (square == _animTo || square == _castleRookTo);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() => _hoverTargetSquare = square);
        return true;
      },
      onLeave: (data) {
        setState(() => _hoverTargetSquare = null);
      },
      onAcceptWithDetails: (details) {
        setState(() => _hoverTargetSquare = null);
        final from = details.data;
        if (widget.onMoveMade != null) {
          widget.onMoveMade!(from, square);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            if (widget.onSquareTapped != null) {
              widget.onSquareTapped!(square);
            }
          },
          child: Container(
            width: size,
            height: size,
            color: squareColor,
            child: Stack(
              children: [
                // Check glow
                if (isCheck)
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          ChessTheme.checkHighlight,
                          Colors.transparent,
                        ],
                        radius: 0.8,
                      ),
                    ),
                  ),

                // File/Rank labels along edges
                if (rIndex == 7)
                  Positioned(
                    right: 2,
                    bottom: 1,
                    child: Text(
                      fileChar,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLight
                            ? ChessTheme.boardDarkSquare
                            : ChessTheme.boardLightSquare,
                      ),
                    ),
                  ),
                if (fIndex == 0)
                  Positioned(
                    left: 2,
                    top: 1,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isLight
                            ? ChessTheme.boardDarkSquare
                            : ChessTheme.boardLightSquare,
                      ),
                    ),
                  ),

                // Legal Move Target Marker
                if (isLegalTarget)
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: piece != null ? size * 0.82 : size * 0.32,
                      height: piece != null ? size * 0.82 : size * 0.32,
                      decoration: BoxDecoration(
                        color: piece != null
                            ? Colors.transparent
                            : ChessTheme.legalMoveDot,
                        shape: BoxShape.circle,
                        border: piece != null
                            ? Border.all(
                                color: ChessTheme.legalCaptureRing,
                                width: 3.5,
                              )
                            : null,
                      ),
                    ),
                  ),

                // Piece Widget with tactile Draggable feedback
                if (piece != null && !hidePieceForAnimation)
                  Center(
                    child: Draggable<String>(
                      data: square,
                      feedback: Material(
                        color: Colors.transparent,
                        child: Transform.scale(
                          scale: 1.18,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ChessPieceSvg(
                              pieceType: piece.type.name,
                              isWhite: piece.color == chess_lib.Color.WHITE,
                              size: size,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.25,
                        child: ChessPieceSvg(
                          pieceType: piece.type.name,
                          isWhite: piece.color == chess_lib.Color.WHITE,
                          size: size,
                        ),
                      ),
                      child: ChessPieceSvg(
                        pieceType: piece.type.name,
                        isWhite: piece.color == chess_lib.Color.WHITE,
                        size: size,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingBadge(String square, double squareSize) {
    if (square.length < 2) return const SizedBox.shrink();

    final file = square[0].toLowerCase().codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(square[1]);

    final col = widget.isFlipped ? (7 - file) : file;
    final row = widget.isFlipped ? (rank - 1) : (8 - rank);

    return Positioned(
      left: col * squareSize + squareSize * 0.58,
      top: row * squareSize - 6,
      child: IgnorePointer(
        child: MoveBadgeWidget(
          classification: widget.currentMoveBadge!,
          size: MoveBadgeSize.small,
        ),
      ),
    );
  }
}
