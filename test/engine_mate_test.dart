import 'package:flutter_test/flutter_test.dart';
import 'package:chess_analysis/services/stockfish_engine_service.dart';

void main() {
  test('Detects Scholar Mate in 1 for White', () async {
    // 1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 position: White has Qxf7#
    final fen = 'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4';
    final eval = await StockfishEngineService.instance.evaluatePosition(fen, depth: 6);

    print('White MateIn: ${eval.mateIn}, BestMove: ${eval.bestMoveUci}');
    expect(eval.bestMoveUci, equals('h5f7'));
    expect(eval.mateIn, equals(1));
    expect(eval.scoreCp, equals(10000.0));
  });

  test('Detects Fools Mate in 1 for Black', () async {
    // 1. f3 e5 2. g4 position: Black has Qh4# (mate in 1)
    final fen = 'rnbqkbnr/pppp1ppp/8/4p3/6P1/5P2/PPPPP2P/RNBQKBNR b KQkq - 0 2';
    final eval = await StockfishEngineService.instance.evaluatePosition(fen, depth: 6);

    print('Black MateIn: ${eval.mateIn}, BestMove: ${eval.bestMoveUci}');
    expect(eval.bestMoveUci, equals('d8h4'));
    expect(eval.mateIn, equals(-1));
    expect(eval.scoreCp, equals(-10000.0));
  });

  test('Detects Already Checkmated position', () async {
    // 1. f3 e5 2. g4 Qh4#
    final fen = 'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';
    final eval = await StockfishEngineService.instance.evaluatePosition(fen, depth: 6);

    print('Checkmated MateIn: ${eval.mateIn}, ScoreCp: ${eval.scoreCp}');
    expect(eval.mateIn, equals(0));
    expect(eval.scoreCp, equals(-10000.0)); // White is checkmated
  });
}
