import 'package:flutter/material.dart';
import '../../models/chess_move_eval.dart';
import '../theme/chess_theme.dart';
import 'move_badge_widget.dart';

class MoveHistoryListWidget extends StatelessWidget {
  final List<MoveEvaluation> moves;
  final int currentMoveIndex; // -1 for start
  final Function(int index) onSelectMove;
  final VoidCallback onFirst;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onLast;
  final VoidCallback onFlip;
  final bool isPlaying;
  final VoidCallback onTogglePlay;

  const MoveHistoryListWidget({
    super.key,
    required this.moves,
    required this.currentMoveIndex,
    required this.onSelectMove,
    required this.onFirst,
    required this.onPrevious,
    required this.onNext,
    required this.onLast,
    required this.onFlip,
    this.isPlaying = false,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Playback Navigation Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ChessTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.flip_camera_android_rounded, size: 20),
                tooltip: 'Flip Board',
                color: ChessTheme.textSecondary,
                onPressed: onFlip,
              ),
              IconButton(
                icon: const Icon(Icons.first_page_rounded, size: 24),
                tooltip: 'Start of Game',
                color: currentMoveIndex >= 0 ? Colors.white : ChessTheme.textMuted,
                onPressed: currentMoveIndex >= 0 ? onFirst : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                tooltip: 'Previous Move',
                color: currentMoveIndex >= 0 ? Colors.white : ChessTheme.textMuted,
                onPressed: currentMoveIndex >= 0 ? onPrevious : null,
              ),
              // Play/Pause auto playback
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 30),
                tooltip: isPlaying ? 'Pause' : 'Auto Play',
                color: ChessTheme.brandGreen,
                onPressed: onTogglePlay,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                tooltip: 'Next Move',
                color: currentMoveIndex < moves.length - 1 ? Colors.white : ChessTheme.textMuted,
                onPressed: currentMoveIndex < moves.length - 1 ? onNext : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page_rounded, size: 24),
                tooltip: 'End of Game',
                color: currentMoveIndex < moves.length - 1 ? Colors.white : ChessTheme.textMuted,
                onPressed: currentMoveIndex < moves.length - 1 ? onLast : null,
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // 2. Horizontal Move Scroller
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: (moves.length / 2).ceil(),
            itemBuilder: (context, pairIdx) {
              final moveNum = pairIdx + 1;
              final whiteIdx = pairIdx * 2;
              final blackIdx = whiteIdx + 1;

              final whiteMove = whiteIdx < moves.length ? moves[whiteIdx] : null;
              final blackMove = blackIdx < moves.length ? moves[blackIdx] : null;

              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ChessTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$moveNum.',
                      style: const TextStyle(
                        color: ChessTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),

                    // White move chip
                    if (whiteMove != null)
                      _moveChip(
                        move: whiteMove,
                        index: whiteIdx,
                        isSelected: currentMoveIndex == whiteIdx,
                      ),

                    // Black move chip
                    if (blackMove != null) ...[
                      const SizedBox(width: 4),
                      _moveChip(
                        move: blackMove,
                        index: blackIdx,
                        isSelected: currentMoveIndex == blackIdx,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _moveChip({
    required MoveEvaluation move,
    required int index,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onSelectMove(index),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? ChessTheme.brandGreen.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: ChessTheme.brandGreen, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              move.san,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 3),
            MoveBadgeWidget(
              classification: move.classification,
              size: MoveBadgeSize.small,
            ),
          ],
        ),
      ),
    );
  }
}
