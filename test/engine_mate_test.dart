import 'package:flutter_test/flutter_test.dart';
import 'package:chess/chess.dart' as chess_lib;
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

  test('Detects Forced Mate in 2 for White (M2)', () async {
    // 1. Rxf7+ Rg7 2. Qxg7# (Mate in 2)
    const fen = 'r5rk/5p1p/5R2/4Q3/8/8/PPP3PP/6K1 w - - 0 1';
    final eval = await StockfishEngineService.instance.evaluatePosition(fen, depth: 8);

    print('White MateIn: ${eval.mateIn}, BestMove: ${eval.bestMoveUci}');
    expect(eval.bestMoveUci, equals('f6f7'));
    expect(eval.mateIn, equals(2));
    expect(eval.scoreCp, equals(10000.0));
  });

  test('Detects Forced Mate in 2 for Black (-M2)', () async {
    // 1... Rxf2+ 2. Rg2 Qxg2# (Mate in 2)
    const fen = '6k1/ppp3pp/8/8/4q3/5r2/5P1P/R5RK b - - 0 1';
    final eval = await StockfishEngineService.instance.evaluatePosition(fen, depth: 8);

    print('Black MateIn: ${eval.mateIn}, BestMove: ${eval.bestMoveUci}');
    expect(eval.mateIn, equals(-2));
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
