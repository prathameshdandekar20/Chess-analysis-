import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:chess_analysis/services/analysis_engine.dart';
import 'package:chess_analysis/models/chess_move_eval.dart';

void main() {
  test('Verify Brilliant move detection on Rxe6', () async {
    final moves = [
      'e4', 'e5',
      'Bc4', 'Nf6',
      'd4', 'exd4',
      'Nf3', 'Nxe4',
      'Qxd4', 'Nf6',
      'Bg5', 'Be7',
      'Nc3', 'c6',
      'O-O-O', 'd5',
      'Rhe1', 'Be6',
      'Bd3', 'Nbd7',
      'Qh4', 'h6',
      'Rxe6', 'fxe6',
      'Bg6+', 'Kf8',
      'Nd4'
    ];

    final review = await AnalysisEngine.instance.reviewGame(
      sanMoves: moves,
    );

    MoveEvaluation? rxe6Eval;
    for (final m in review.moves) {
      if (m.san.startsWith('Rxe6')) {
        rxe6Eval = m;
        stdout.writeln('Rxe6 classification: ${m.classification.displayName}');
        stdout.writeln('Rxe6 is Brilliant? ${m.classification == MoveClassification.brilliant}');
        stdout.writeln('Rxe6 commentary: ${m.coachCommentary}');
      }
    }

    expect(rxe6Eval, isNotNull);
    expect(rxe6Eval!.classification, equals(MoveClassification.brilliant));
  });
}
