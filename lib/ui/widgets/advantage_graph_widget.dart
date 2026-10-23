import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/chess_move_eval.dart';
import '../theme/chess_theme.dart';

class AdvantageGraphWidget extends StatelessWidget {
  final List<MoveEvaluation> moves;
  final int currentMoveIndex;
  final Function(int moveIndex)? onMoveSelected;
  final double height;

  const AdvantageGraphWidget({
    super.key,
    required this.moves,
    required this.currentMoveIndex,
    this.onMoveSelected,
    this.height = 95,
  });

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[
      const FlSpot(0, 0), // Starting position
    ];

    for (int i = 0; i < moves.length; i++) {
      final m = moves[i];
      // Convert centipawns to clamped eval range [-8.0, 8.0]
      double val;
      if (m.mateAfter != null) {
        val = m.mateAfter! > 0 ? 8.0 : -8.0;
      } else {
        val = (m.evalAfter / 100.0).clamp(-8.0, 8.0);
      }
      spots.add(FlSpot((i + 1).toDouble(), val));
    }

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              const Text(
                'EVALUATION TIMELINE',
                style: TextStyle(
                  color: ChessTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  _legendDot(MoveClassification.brilliant.color, 'Brilliant'),
                  const SizedBox(width: 8),
                  _legendDot(MoveClassification.blunder.color, 'Blunder'),
                  const SizedBox(width: 8),
                  _legendDot(MoveClassification.mistake.color, 'Mistake'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: moves.length.toDouble(),
                minY: -8.0,
                maxY: 8.0,
                lineTouchData: LineTouchData(
                  touchCallback: (event, response) {
                    if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
                      final spot = response.lineBarSpots!.first;
                      final selectedIdx = (spot.x - 1).round().clamp(0, moves.length - 1);
                      if (onMoveSelected != null) {
                        onMoveSelected!(selectedIdx);
                      }
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = (spot.x - 1).round();
                        if (idx >= 0 && idx < moves.length) {
                          final m = moves[idx];
                          return LineTooltipItem(
                            '${m.san} (${m.displayEval})\n${m.classification.displayName}',
                            TextStyle(
                              color: m.classification.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 4.0,
                  getDrawingHorizontalLine: (val) {
                    if (val == 0) {
                      return FlLine(color: Colors.white.withOpacity(0.35), strokeWidth: 1.2);
                    }
                    return FlLine(color: Colors.white.withOpacity(0.05), strokeWidth: 1);
                  },
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    color: Colors.white.withOpacity(0.85),
                    barWidth: 2.0,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, barData) {
                        final idx = (spot.x - 1).round();
                        if (idx < 0 || idx >= moves.length) return false;
                        final c = moves[idx].classification;
                        return c == MoveClassification.blunder ||
                               c == MoveClassification.mistake ||
                               c == MoveClassification.miss ||
                               c == MoveClassification.brilliant ||
                               idx == currentMoveIndex;
                      },
                      getDotPainter: (spot, percent, barData, index) {
                        final idx = (spot.x - 1).round();
                        if (idx >= 0 && idx < moves.length) {
                          final isCurrent = (idx == currentMoveIndex);
                          final c = moves[idx].classification;
                          return FlDotCirclePainter(
                            radius: isCurrent ? 5.0 : 3.5,
                            color: c.color,
                            strokeWidth: isCurrent ? 2.0 : 1.0,
                            strokeColor: Colors.white,
                          );
                        }
                        return FlDotCirclePainter(radius: 2, color: Colors.white);
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: ChessTheme.brandGreen.withOpacity(0.12),
                      cutOffY: 0,
                      applyCutOffY: true,
                    ),
                    aboveBarData: BarAreaData(
                      show: true,
                      color: Colors.redAccent.withOpacity(0.12),
                      cutOffY: 0,
                      applyCutOffY: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: ChessTheme.textMuted, fontSize: 9)),
      ],
    );
  }
}
