import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/stockfish_engine_service.dart';
import 'services/coach_voice_service.dart';
import 'ui/theme/chess_theme.dart';
import 'ui/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style (dark status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: ChessTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Stockfish engine and Coach Voice TTS asynchronously
  StockfishEngineService.instance.init();
  CoachVoiceService.instance.init();

  runApp(const ChessAnalysisApp());
}

class ChessAnalysisApp extends StatelessWidget {
  const ChessAnalysisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Analysis & Stockfish',
      debugShowCheckedModeBanner: false,
      theme: ChessTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}
