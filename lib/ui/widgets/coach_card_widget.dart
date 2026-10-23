import 'package:flutter/material.dart';
import '../../models/chess_move_eval.dart';
import '../../models/coach_profile.dart';
import '../../services/coach_voice_service.dart';
import '../theme/chess_theme.dart';
import 'move_badge_widget.dart';

class CoachCardWidget extends StatelessWidget {
  final MoveEvaluation? currentMove;
  final CoachProfile coach;
  final VoidCallback? onSelectCoach;
  final VoidCallback? onRetryMistake;
  final VoidCallback? onToggleBestMoveArrow;
  final bool showBestMoveArrow;

  const CoachCardWidget({
    super.key,
    required this.currentMove,
    required this.coach,
    this.onSelectCoach,
    this.onRetryMistake,
    this.onToggleBestMoveArrow,
    this.showBestMoveArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    if (currentMove == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ChessTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onSelectCoach,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: ChessTheme.surfaceElevated,
                child: Text(coach.avatarEmoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Navigate through the game moves below or use playback controls.',
                style: TextStyle(color: ChessTheme.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final move = currentMove!;
    final isNegative = move.classification.isNegative;

    // Generate customized commentary based on current coach
    final commentary = coach.generateCommentary(
      classification: move.classification,
      san: move.san,
      bestMoveSan: move.bestMoveSan,
      isWhite: move.isWhite,
      evalAfterCp: move.evalAfter,
      openingName: 'the opening',
      captured: false,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChessTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: move.classification.color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: move.classification.color.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Coach Avatar (clickable) + Move Badge + Classification Title
          Row(
            children: [
              GestureDetector(
                onTap: onSelectCoach,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ChessTheme.surfaceElevated,
                    border: Border.all(color: coach.themeColor, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: coach.themeColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(coach.avatarEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              MoveBadgeWidget(
                classification: move.classification,
                size: MoveBadgeSize.regular,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          move.classification.displayName,
                          style: TextStyle(
                            color: move.classification.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Coach Name Tag
                        InkWell(
                          onTap: onSelectCoach,
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: coach.themeColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  coach.name,
                                  style: TextStyle(
                                    color: coach.themeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 12, color: Colors.white70),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${move.isWhite ? "White" : "Black"} played ${move.san}',
                      style: const TextStyle(
                        color: ChessTheme.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Eval chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: ChessTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Text(
                  move.displayEval,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Voice Commentary Audio Button
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  CoachVoiceService.instance.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  color: CoachVoiceService.instance.isMuted ? Colors.white38 : coach.themeColor,
                  size: 22,
                ),
                tooltip: CoachVoiceService.instance.isMuted ? 'Unmute Coach Voice' : 'Hear Coach Commentary',
                onPressed: () {
                  if (CoachVoiceService.instance.isMuted) {
                    CoachVoiceService.instance.toggleMute();
                  }
                  CoachVoiceService.instance.speakCommentary(
                    commentary: commentary,
                    personality: coach.personality,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Commentary text in Coach's voice
          Text(
            commentary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.35,
            ),
          ),

          // Action buttons: "Retry Mistake" / "Show Best Move"
          if (isNegative || move.bestMoveSan.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (isNegative && onRetryMistake != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onRetryMistake,
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: const Text('Retry Mistake', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChessTheme.brandGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                if (isNegative && onRetryMistake != null) const SizedBox(width: 8),
                if (onToggleBestMoveArrow != null)
                  OutlinedButton.icon(
                    onPressed: onToggleBestMoveArrow,
                    icon: Icon(
                      showBestMoveArrow ? Icons.visibility_off : Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.white70,
                    ),
                    label: Text(
                      showBestMoveArrow ? 'Hide Best Move' : 'Show ${move.bestMoveSan}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
