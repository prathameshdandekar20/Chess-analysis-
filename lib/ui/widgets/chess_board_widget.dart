import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../theme/chess_theme.dart';
import '../../models/chess_move_eval.dart';
import 'chess_piece_svg.dart';
import 'board_arrows_painter.dart';
import 'move_badge_widget.dart';

class ChessBoardWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final squareSize = boardSize / 8.0;

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
                // 1. Board Squares & Pieces
                Column(
                  children: List.generate(8, (rIndex) {
                    final rank = isFlipped ? (rIndex + 1) : (8 - rIndex);
                    return Row(
                      children: List.generate(8, (fIndex) {
                        final file = isFlipped ? (7 - fIndex) : fIndex;
                        final fileChar = String.fromCharCode('a'.codeUnitAt(0) + file);
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
                        arrows: arrows,
                        isFlipped: isFlipped,
                      ),
                    ),
                  ),
                ),

                // 3. Floating Move Badge on Destination Square
                if (currentMoveBadge != null && badgeSquare != null)
                  _buildFloatingBadge(badgeSquare!, squareSize),
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
    final isSelected = square == selectedSquare;
    final isLastMove = square == lastMoveFrom || square == lastMoveTo;
    final isLegalTarget = legalDestinations.contains(square);

    // Check indicator
    bool isCheck = false;
    final piece = game.get(square);
    if (piece != null && piece.type == chess_lib.PieceType.KING) {
      final isWhite = piece.color == chess_lib.Color.WHITE;
      if (game.in_check && game.turn == piece.color) {
        isCheck = true;
      }
    }

    Color squareColor = isLight ? ChessTheme.boardLightSquare : ChessTheme.boardDarkSquare;
    if (isSelected) {
      squareColor = ChessTheme.selectedSquareHighlight;
    } else if (isLastMove) {
      squareColor = Color.alphaBlend(ChessTheme.lastMoveHighlight, squareColor);
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final from = details.data;
        if (onMoveMade != null) {
          onMoveMade!(from, square);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () {
            if (onSquareTapped != null) {
              onSquareTapped!(square);
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
                        color: isLight ? ChessTheme.boardDarkSquare : ChessTheme.boardLightSquare,
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
                        color: isLight ? ChessTheme.boardDarkSquare : ChessTheme.boardLightSquare,
                      ),
                    ),
                  ),

                // Legal Move Target Marker
                if (isLegalTarget)
                  Center(
                    child: Container(
                      width: piece != null ? size * 0.8 : size * 0.32,
                      height: piece != null ? size * 0.8 : size * 0.32,
                      decoration: BoxDecoration(
                        color: piece != null ? Colors.transparent : ChessTheme.legalMoveDot,
                        shape: BoxShape.circle,
                        border: piece != null
                            ? Border.all(color: ChessTheme.legalCaptureRing, width: 3.5)
                            : null,
                      ),
                    ),
                  ),

                // Piece Widget with Draggable
                if (piece != null)
                  Center(
                    child: Draggable<String>(
                      data: square,
                      feedback: Material(
                        color: Colors.transparent,
                        child: ChessPieceSvg(
                          pieceType: piece.type.name,
                          isWhite: piece.color == chess_lib.Color.WHITE,
                          size: size * 1.15,
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
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

    final col = isFlipped ? (7 - file) : file;
    final row = isFlipped ? (rank - 1) : (8 - rank);

    return Positioned(
      left: col * squareSize + squareSize * 0.58,
      top: row * squareSize - 6,
      child: IgnorePointer(
        child: MoveBadgeWidget(
          classification: currentMoveBadge!,
          size: MoveBadgeSize.small,
        ),
      ),
    );
  }
}
