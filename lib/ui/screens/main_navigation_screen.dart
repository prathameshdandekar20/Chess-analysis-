import 'package:flutter/material.dart';
import '../theme/chess_theme.dart';
import '../../services/sample_review_service.dart';
import 'game_review_screen.dart';
import 'live_analysis_screen.dart';
import 'play_bot_screen.dart';
import 'pgn_import_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    GameReviewScreen(reviewData: SampleReviewService.getMorphyOperaReview()),
    const LiveAnalysisScreen(),
    const PlayBotScreen(),
    const PgnImportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: ChessTheme.surface,
        selectedItemColor: ChessTheme.brandGreen,
        unselectedItemColor: ChessTheme.textMuted,
        selectedFontSize: 11.5,
        unselectedFontSize: 11.0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph_rounded),
            activeIcon: Icon(Icons.auto_graph_rounded, color: ChessTheme.brandGreen),
            label: 'Game Review',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore, color: ChessTheme.brandGreen),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy, color: ChessTheme.brandGreen),
            label: 'Play Bot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books, color: ChessTheme.brandGreen),
            label: 'Import PGN',
          ),
        ],
      ),
    );
  }
}
