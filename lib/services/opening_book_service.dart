class OpeningInfo {
  final String eco;
  final String name;
  final String moves;

  const OpeningInfo({
    required this.eco,
    required this.name,
    required this.moves,
  });
}

class OpeningBookService {
  static final List<OpeningInfo> _openings = [
    const OpeningInfo(eco: 'B90', name: 'Sicilian Defense: Najdorf Variation', moves: 'e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 a6'),
    const OpeningInfo(eco: 'B70', name: 'Sicilian Defense: Dragon Variation', moves: 'e4 c5 Nf3 d6 d4 cxd4 Nxd4 Nf6 Nc3 g6'),
    const OpeningInfo(eco: 'B22', name: 'Sicilian Defense: Alapin Variation', moves: 'e4 c5 c3'),
    const OpeningInfo(eco: 'B33', name: 'Sicilian Defense: Sveshnikov Variation', moves: 'e4 c5 Nf3 Nc6 d4 cxd4 Nxd4 Nf6 Nc3 e5'),
    const OpeningInfo(eco: 'B20', name: 'Sicilian Defense', moves: 'e4 c5'),
    const OpeningInfo(eco: 'C65', name: 'Ruy Lopez: Berlin Defense', moves: 'e4 e5 Nf3 Nc6 Bb5 Nf6'),
    const OpeningInfo(eco: 'C60', name: 'Ruy Lopez', moves: 'e4 e5 Nf3 Nc6 Bb5'),
    const OpeningInfo(eco: 'C51', name: 'Evans Gambit', moves: 'e4 e5 Nf3 Nc6 Bc4 Bc5 b4'),
    const OpeningInfo(eco: 'C50', name: 'Italian Game', moves: 'e4 e5 Nf3 Nc6 Bc4'),
    const OpeningInfo(eco: 'C55', name: 'Two Knights Defense', moves: 'e4 e5 Nf3 Nc6 Bc4 Nf6'),
    const OpeningInfo(eco: 'C42', name: 'Petrov Defense', moves: 'e4 e5 Nf3 Nf6'),
    const OpeningInfo(eco: 'C45', name: 'Scotch Game', moves: 'e4 e5 Nf3 Nc6 d4'),
    const OpeningInfo(eco: 'C20', name: "King's Pawn Game", moves: 'e4 e5'),
    const OpeningInfo(eco: 'C00', name: 'French Defense', moves: 'e4 e6'),
    const OpeningInfo(eco: 'C10', name: 'French Defense: Paulsen Variation', moves: 'e4 e6 d4 d5 Nc3'),
    const OpeningInfo(eco: 'C02', name: 'French Defense: Advance Variation', moves: 'e4 e6 d4 d5 e5'),
    const OpeningInfo(eco: 'B10', name: 'Caro-Kann Defense', moves: 'e4 c6'),
    const OpeningInfo(eco: 'B12', name: 'Caro-Kann Defense: Advance Variation', moves: 'e4 c6 d4 d5 e5'),
    const OpeningInfo(eco: 'B01', name: 'Scandinavian Defense', moves: 'e4 d5'),
    const OpeningInfo(eco: 'B02', name: "Alekhine's Defense", moves: 'e4 Nf6'),
    const OpeningInfo(eco: 'B06', name: 'Modern Defense', moves: 'e4 g6'),
    const OpeningInfo(eco: 'B07', name: 'Pirc Defense', moves: 'e4 d6 d4 Nf6 Nc3 g6'),
    const OpeningInfo(eco: 'D30', name: "Queen's Gambit Declined", moves: 'd4 d5 c4 e6'),
    const OpeningInfo(eco: 'D20', name: "Queen's Gambit Accepted", moves: 'd4 d5 c4 dxc4'),
    const OpeningInfo(eco: 'D10', name: 'Slav Defense', moves: 'd4 d5 c4 c6'),
    const OpeningInfo(eco: 'D06', name: "Queen's Gambit", moves: 'd4 d5 c4'),
    const OpeningInfo(eco: 'D00', name: 'London System', moves: 'd4 d5 Bf4'),
    const OpeningInfo(eco: 'D02', name: "Queen's Pawn Game: London System", moves: 'd4 d5 Nf3 Nf6 Bf4'),
    const OpeningInfo(eco: 'E60', name: "King's Indian Defense", moves: 'd4 Nf6 c4 g6'),
    const OpeningInfo(eco: 'E20', name: 'Nimzo-Indian Defense', moves: 'd4 Nf6 c4 e6 Nc3 Bb4'),
    const OpeningInfo(eco: 'E00', name: 'Catalan Opening', moves: 'd4 Nf6 c4 e6 g3'),
    const OpeningInfo(eco: 'D70', name: 'Grünfeld Defense', moves: 'd4 Nf6 c4 g6 Nc3 d5'),
    const OpeningInfo(eco: 'A56', name: 'Benoni Defense', moves: 'd4 Nf6 c4 c5 d5'),
    const OpeningInfo(eco: 'A80', name: 'Dutch Defense', moves: 'd4 f5'),
    const OpeningInfo(eco: 'A40', name: "Queen's Pawn Opening", moves: 'd4'),
    const OpeningInfo(eco: 'A10', name: 'English Opening', moves: 'c4'),
    const OpeningInfo(eco: 'A04', name: 'Réti Opening', moves: 'Nf3'),
    const OpeningInfo(eco: 'A02', name: "Bird's Opening", moves: 'f4'),
    const OpeningInfo(eco: 'C30', name: "King's Gambit", moves: 'e4 e5 f4'),
    const OpeningInfo(eco: 'C33', name: "King's Gambit Accepted", moves: 'e4 e5 f4 exf4'),
  ];

  /// Finds the best matching opening for a sequence of SAN moves
  static OpeningInfo? findOpeningBySan(List<String> sanMoves) {
    if (sanMoves.isEmpty) return null;
    final playedStr = sanMoves.join(' ');

    OpeningInfo? bestMatch;
    int maxWords = 0;

    for (final op in _openings) {
      if (playedStr.startsWith(op.moves)) {
        final count = op.moves.split(' ').length;
        if (count > maxWords) {
          maxWords = count;
          bestMatch = op;
        }
      }
    }

    // Also check if the played moves are a prefix of an opening book
    if (bestMatch == null) {
      for (final op in _openings) {
        if (op.moves.startsWith(playedStr)) {
          return op;
        }
      }
    }

    return bestMatch;
  }

  /// Determines if a specific move index is considered an opening book move
  static bool isBookMove(List<String> sanMoves, int moveIndex) {
    if (moveIndex >= sanMoves.length) return false;
    final prefix = sanMoves.sublist(0, moveIndex + 1).join(' ');
    for (final op in _openings) {
      if (op.moves.startsWith(prefix)) {
        return true;
      }
    }
    return false;
  }
}
