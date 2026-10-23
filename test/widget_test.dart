import 'package:flutter_test/flutter_test.dart';
import 'package:chess_analysis/main.dart';

void main() {
  testWidgets('App loads and displays Game Review', (WidgetTester tester) async {
    await tester.pumpWidget(const ChessAnalysisApp());
    expect(find.text('Game Review'), findsAtLeastNWidgets(1));
  });
}
