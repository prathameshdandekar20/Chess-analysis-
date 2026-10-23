import 'package:flutter/material.dart';
import '../../services/analysis_engine.dart';
import '../theme/chess_theme.dart';
import 'game_review_screen.dart';

class PgnImportScreen extends StatefulWidget {
  const PgnImportScreen({super.key});

  @override
  State<PgnImportScreen> createState() => _PgnImportScreenState();
}

class _PgnImportScreenState extends State<PgnImportScreen> {
  final TextEditingController _pgnController = TextEditingController();
  final TextEditingController _whiteController = TextEditingController(text: 'White');
  final TextEditingController _blackController = TextEditingController(text: 'Black');

  bool _isAnalyzing = false;
  double _analysisProgress = 0.0;
  String _analysisStatus = '';

  static const Map<String, Map<String, dynamic>> _famousGames = {
    'Morphy\'s Opera Game (1858)': {
      'white': 'Paul Morphy',
      'black': 'Duke & Count',
      'moves': [
        'e4', 'e5', 'Nf3', 'd6', 'd4', 'Bg4', 'dxe5', 'Bxf3', 'Qxf3', 'dxe5',
        'Bc4', 'Nf6', 'Qb3', 'Qe7', 'Nc3', 'c6', 'Bg5', 'b5', 'Nxb5', 'cxb5',
        'Bxb5+', 'Nbd7', 'O-O-O', 'Rd8', 'Rxd7', 'Rxd7', 'Rd1', 'Qe6', 'Bxd7+', 'Nxd7',
        'Qb8+', 'Nxb8', 'Rd8#'
      ],
      'desc': 'Paul Morphy\'s historic masterpiece in the Paris Opera House featuring the legendary queen sacrifice 16.Qb8+!',
    },
    'Kasparov\'s Immortal (1999)': {
      'white': 'Garry Kasparov',
      'black': 'Veselin Topalov',
      'moves': [
        'e4', 'd6', 'd4', 'Nf6', 'Nc3', 'g6', 'Be3', 'Bg7', 'Qd2', 'c6',
        'f3', 'b5', 'Nge2', 'Nbd7', 'Bh6', 'Bxh6', 'Qxh6', 'Bb7', 'a3', 'e5',
        'O-O-O', 'Qe7', 'Kb1', 'a6', 'Nc1', 'O-O-O', 'Nb3', 'exd4', 'Rxd4', 'c5',
        'Rd1', 'Nb6', 'g3', 'Kb8', 'Na5', 'Ba8', 'Bh3', 'd5', 'Qf4+', 'Ka7',
        'Rhe1', 'd4', 'Nd5', 'Nbxd5', 'exd5', 'Qd6', 'Rxd4', 'cxd4', 'Re7+', 'Kb6',
        'Qxd4+', 'Kxa5', 'b4+', 'Ka4', 'Qc3', 'Qxd5', 'Ra7', 'Bb7', 'Rxb7', 'Qc4',
        'Qxf6', 'Kxa3', 'Qxa6+', 'Kxb4', 'c3+', 'Kxc3', 'Qa1+', 'Kd2', 'Qb2+', 'Kd1',
        'Bf1', 'Rd2', 'Rd7', 'Rxd7', 'Bxc4', 'bxc4', 'Qxh8', 'Rd3', 'Qa8', 'c3',
        'Qa4+', 'Ke1', 'f4', 'f5', 'Kc1', 'Rd2', 'Qa7'
      ],
      'desc': 'Regarded as one of the greatest chess games in history featuring 24.Rxd4!! and an incredible king chase.',
    },
    'Game of the Century (1956)': {
      'white': 'Donald Byrne',
      'black': 'Bobby Fischer (Age 13)',
      'moves': [
        'Nf3', 'Nf6', 'c4', 'g6', 'Nc3', 'Bg7', 'd4', 'O-O', 'Bf4', 'd5',
        'Qb3', 'dxc4', 'Qxc4', 'c6', 'e4', 'Nbd7', 'Rd1', 'Nb6', 'Qc5', 'Bg4',
        'Bg5', 'Na4', 'Qa3', 'Nxc3', 'bxc3', 'Nxe4', 'Bxe7', 'Qb6', 'Bc4', 'Nxc3',
        'Bc5', 'Rfe8+', 'Kf1', 'Be6', 'Bxb6', 'Bxc4+', 'Kg1', 'Ne2+', 'Kf1', 'Nxd4+',
        'Kg1', 'Ne2+', 'Kf1', 'Nc3+', 'Kg1', 'axb6', 'Qb4', 'Ra4', 'Qxb6', 'Nxd1',
        'h3', 'Rxa2', 'Kh2', 'Nxf2', 'Re1', 'Rxe1', 'Qd8+', 'Bf8', 'Nxe1', 'Bd5',
        'Nf3', 'Ne4', 'Qb8', 'b5', 'h4', 'h5', 'Ne5', 'Kg7', 'Kg1', 'Bc5+',
        'Kf1', 'Ng3+', 'Ke1', 'Bb4+', 'Kd1', 'Bb3+', 'Kc1', 'Ne2+', 'Kb1', 'Nc3+',
        'Kc1', 'Rc2#'
      ],
      'desc': '13-year-old Bobby Fischer plays the stunning queen sacrifice 17...Be6!! to dismantle Byrne\'s king.',
    },
  };

  void _loadPreset(String key) {
    final game = _famousGames[key]!;
    _whiteController.text = game['white'];
    _blackController.text = game['black'];
    final moves = (game['moves'] as List).cast<String>();

    final buffer = StringBuffer();
    for (int i = 0; i < moves.length; i++) {
      if (i % 2 == 0) {
        buffer.write('${(i ~/ 2) + 1}. ');
      }
      buffer.write('${moves[i]} ');
    }
    _pgnController.text = buffer.toString().trim();
  }

  void _startAnalysis() async {
    final text = _pgnController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste a PGN or select a famous game preset!')),
      );
      return;
    }

    final tokens = text.replaceAll(RegExp(r'\d+\.\s*'), '').split(RegExp(r'\s+'));
    final moves = tokens.where((t) => t.isNotEmpty && !t.contains('[') && !t.contains(']') && t != '*' && !t.contains('-')).toList();

    if (moves.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find any valid chess moves in the text.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0.0;
      _analysisStatus = 'Initializing Stockfish...';
    });

    final reviewData = await AnalysisEngine.instance.reviewGame(
      sanMoves: moves,
      whitePlayer: _whiteController.text.trim().isNotEmpty ? _whiteController.text.trim() : 'White',
      blackPlayer: _blackController.text.trim().isNotEmpty ? _blackController.text.trim() : 'Black',
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _analysisProgress = progress;
            _analysisStatus = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() => _isAnalyzing = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => GameReviewScreen(reviewData: reviewData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChessTheme.background,
      appBar: AppBar(
        title: const Text('Import PGN / Masterpieces'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Famous games chips
              const Text(
                'FEATURED MASTERPIECES',
                style: TextStyle(
                  color: ChessTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _famousGames.keys.map((title) {
                  return ActionChip(
                    backgroundColor: ChessTheme.surfaceElevated,
                    label: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    avatar: const Icon(Icons.star, size: 14, color: ChessTheme.brandGreen),
                    onPressed: () => _loadPreset(title),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Player Names Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _whiteController,
                      decoration: const InputDecoration(
                        labelText: 'White Player',
                        filled: true,
                        fillColor: ChessTheme.surfaceCard,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _blackController,
                      decoration: const InputDecoration(
                        labelText: 'Black Player',
                        filled: true,
                        fillColor: ChessTheme.surfaceCard,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // PGN Input Field
              TextField(
                controller: _pgnController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Paste PGN notation here (e.g. 1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 ...)',
                  filled: true,
                  fillColor: ChessTheme.surfaceCard,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),

              const SizedBox(height: 16),

              // Analysis progress or Analyze Button
              if (_isAnalyzing) ...[
                LinearProgressIndicator(
                  value: _analysisProgress,
                  backgroundColor: ChessTheme.surfaceElevated,
                  color: ChessTheme.brandGreen,
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Text(
                  _analysisStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ChessTheme.brandGreenLight, fontSize: 12.5),
                ),
              ] else
                ElevatedButton.icon(
                  onPressed: _startAnalysis,
                  icon: const Icon(Icons.rocket_launch_rounded),
                  label: const Text(
                    'Analyze Game with Stockfish',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChessTheme.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
