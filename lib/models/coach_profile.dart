import 'package:flutter/material.dart';
import 'chess_move_eval.dart';

enum CoachPersonality {
  classic,
  gotham,
  grandmaster,
  roast,
  encouraging,
  ruthless,
}

class CoachProfile {
  final String id;
  final String name;
  final String title;
  final String tagline;
  final String avatarEmoji;
  final Color themeColor;
  final CoachPersonality personality;

  const CoachProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.tagline,
    required this.avatarEmoji,
    required this.themeColor,
    required this.personality,
  });

  static const List<CoachProfile> presets = [
    CoachProfile(
      id: 'danny',
      name: 'Coach Danny',
      title: 'Head Coach • Balanced & Educational',
      tagline: 'Clear explanations, tactical insights, and solid fundamentals.',
      avatarEmoji: '👨‍🏫',
      themeColor: Color(0xFF81B64C),
      personality: CoachPersonality.classic,
    ),
    CoachProfile(
      id: 'gotham',
      name: 'Coach Gotham',
      title: 'High Energy • Danger Levels',
      tagline: 'Caps lock excitement, hype sacrifices, and checking danger levels!',
      avatarEmoji: '⚡',
      themeColor: Color(0xFFFF9800),
      personality: CoachPersonality.gotham,
    ),
    CoachProfile(
      id: 'vishy',
      name: 'GM Vishy',
      title: 'Grandmaster • Calm & Deep Strategy',
      tagline: 'Strategic depth, pawn structures, and endgame masterclass.',
      avatarEmoji: '🧘‍♂️',
      themeColor: Color(0xFF29B6F6),
      personality: CoachPersonality.grandmaster,
    ),
    CoachProfile(
      id: 'roast',
      name: 'Coach Sarcasm',
      title: 'The Roaster • Brutally Honest',
      tagline: 'Roasts blunders, questions life choices, begrudgingly praises brilliancies.',
      avatarEmoji: '🌶️',
      themeColor: Color(0xFFE53935),
      personality: CoachPersonality.roast,
    ),
    CoachProfile(
      id: 'sophia',
      name: 'Coach Sophia',
      title: 'Friendly Mentor • Positive & Kind',
      tagline: 'Supportive, uplifting, and believes you can bounce back from any mistake!',
      avatarEmoji: '🌟',
      themeColor: Color(0xFFAB47BC),
      personality: CoachPersonality.encouraging,
    ),
    CoachProfile(
      id: 'magnus',
      name: 'Champion Magnus',
      title: 'World Champion • Ruthless Precision',
      tagline: 'Perfectionist, unforgiving, demanding the absolute highest accuracy.',
      avatarEmoji: '👑',
      themeColor: Color(0xFF00E676),
      personality: CoachPersonality.ruthless,
    ),
  ];

  String generateCommentary({
    required MoveClassification classification,
    required String san,
    required String bestMoveSan,
    required bool isWhite,
    required double evalAfterCp,
    required String openingName,
    required bool captured,
  }) {
    if (san.contains('#')) {
      switch (personality) {
        case CoachPersonality.gotham:
          return '👑 BOOM!! THAT IS CHECKMATE! GAME OVER! Clean finish with $san!';
        case CoachPersonality.grandmaster:
          return '👑 Beautiful checkmate! $san concludes the game with grandmaster accuracy.';
        case CoachPersonality.roast:
          return '👑 Wow, you actually found checkmate with $san. Even a broken clock is right twice a day.';
        case CoachPersonality.encouraging:
          return '👑 Checkmate! Stunning finish with $san, congratulations!';
        case CoachPersonality.ruthless:
          return '👑 Checkmate. $san is completely clinical, game over.';
        case CoachPersonality.classic:
          return '👑 Checkmate! $san delivers a decisive victory.';
      }
    }

    switch (personality) {
      case CoachPersonality.gotham:
        return _gothamCommentary(classification, san, bestMoveSan, openingName, captured);
      case CoachPersonality.grandmaster:
        return _vishyCommentary(classification, san, bestMoveSan, openingName, captured);
      case CoachPersonality.roast:
        return _roastCommentary(classification, san, bestMoveSan, openingName, captured);
      case CoachPersonality.encouraging:
        return _sophiaCommentary(classification, san, bestMoveSan, openingName, captured);
      case CoachPersonality.ruthless:
        return _magnusCommentary(classification, san, bestMoveSan, openingName, captured);
      case CoachPersonality.classic:
        return _classicCommentary(classification, san, bestMoveSan, openingName, captured);
    }
  }

  String _classicCommentary(MoveClassification c, String san, String best, String op, bool cap) {
    switch (c) {
      case MoveClassification.brilliant:
        return '💎 Brilliant piece sacrifice! $san blows open the enemy defense while keeping a dominating advantage.';
      case MoveClassification.great:
        return '⚡ Great find! $san is a critical move that keeps the pressure on the opponent.';
      case MoveClassification.best:
        return cap
            ? '⭐ Best move. Capturing with $san maintains maximum piece coordination.'
            : '⭐ Best move. Stockfish approves: $san is the most accurate continuation.';
      case MoveClassification.excellent:
        return '👍 Excellent move. $san maintains the advantage and develops your plan nicely.';
      case MoveClassification.good:
        return '✔️ Good move. $san is solid, though $best was slightly more active.';
      case MoveClassification.book:
        return '📖 Book move! Continuing theoretical main lines in the $op.';
      case MoveClassification.inaccuracy:
        return '⁉️ Inaccuracy. $san gives away some initiative. Better was $best.';
      case MoveClassification.mistake:
        return '❓ Mistake! $san allows the opponent counterplay. Best was $best.';
      case MoveClassification.blunder:
        return '❌ Blunder! $san severely damages your position. You should have played $best.';
      case MoveClassification.miss:
        return '⭕ Missed win! You had a decisive tactical advantage with $best, but played $san.';
    }
  }

  String _gothamCommentary(MoveClassification c, String san, String best, String op, bool cap) {
    switch (c) {
      case MoveClassification.brilliant:
        return '💎 AND YOU SACRIFICED... THE PIECE!! $san is absolutely INSANE! Full engine approved!';
      case MoveClassification.great:
        return '⚡ OH WHAT A MOVE! $san finds the only critical resource on the board! Huge!';
      case MoveClassification.best:
        return cap
            ? '⭐ BOOM! Capturing with $san is 100% engine best! No debate.'
            : '⭐ Look at the computer! $san is the top recommendation. Clean chess.';
      case MoveClassification.excellent:
        return '👍 Very nice! $san keeps the pressure sky-high. I like it.';
      case MoveClassification.good:
        return '✔️ Reasonable move, but $best had way more danger levels!';
      case MoveClassification.book:
        return '📖 Theory! You know your $op! Respect!';
      case MoveClassification.inaccuracy:
        return '⁉️ No no no, check your danger levels! $san gives them breathing room. $best was right there!';
      case MoveClassification.mistake:
        return '❓ OH NO! $san is a big tactical slip! You had to play $best!';
      case MoveClassification.blunder:
        return '❌ YOU HUNG A PIECE! $san is a massive blunder! Why not $best?! Call an ambulance!';
      case MoveClassification.miss:
        return '⭕ YOU MISSED THE WIN! $best was right in front of you for a crushing victory!';
    }
  }

  String _vishyCommentary(MoveClassification c, String san, String best, String op, bool cap) {
    switch (c) {
      case MoveClassification.brilliant:
        return '💎 A profound tactical sacrifice. With $san, you calculated the king weaknesses brilliantly.';
      case MoveClassification.great:
        return '⚡ An exceptional find. $san demonstrates high strategic understanding of the position.';
      case MoveClassification.best:
        return '⭐ Grandmaster precision. $san maximizes space, activity, and king security.';
      case MoveClassification.excellent:
        return '👍 Very solid positional choice. $san restricts the opponent\'s key pawn breaks.';
      case MoveClassification.good:
        return '✔️ A sensible move. In master games, $best is slightly more energetic.';
      case MoveClassification.book:
        return '📖 Sound opening development. Entering standard theoretical structures in the $op.';
      case MoveClassification.inaccuracy:
        return '⁉️ Inaccuracy. $san allows the opponent an unnecessary tactical counter-punch. $best was cleaner.';
      case MoveClassification.mistake:
        return '❓ A positional mistake. $san concedes central squares. Retaining control with $best was essential.';
      case MoveClassification.blunder:
        return '❌ Critical tactical oversight. $san loses decisive material. $best was required.';
      case MoveClassification.miss:
        return '⭕ A missed tactical opportunity. You had a forced advantage with $best.';
    }
  }

  String _roastCommentary(MoveClassification c, String san, String best, String op, bool cap) {
    switch (c) {
      case MoveClassification.brilliant:
        return '💎 Wait... did you mean to play that? $san is actually brilliant! Even I have to admit that was legendary.';
      case MoveClassification.great:
        return '⚡ Look at you finding $san! Maybe there is hope for your rating after all.';
      case MoveClassification.best:
        return '⭐ Stockfish likes $san. Don\'t let it go to your head, it was the only obvious move.';
      case MoveClassification.excellent:
        return '👍 Not bad at all. At least you didn\'t hang your queen like last time.';
      case MoveClassification.good:
        return '✔️ It\'s fine, I guess. $best would have actually accomplished something though.';
      case MoveClassification.book:
        return '📖 You remembered your opening book? I\'m genuinely shocked.';
      case MoveClassification.inaccuracy:
        return '⁉️ What was the plan here with $san? Hope they close their eyes? $best was clearly better.';
      case MoveClassification.mistake:
        return '❓ Yikes. $san is painful to watch. $best was sitting there waving at you.';
      case MoveClassification.blunder:
        return '❌ Did your mouse slip or is this a charity donation? $san is an absolute catastrophe. Best was $best.';
      case MoveClassification.miss:
        return '⭕ You had an open goal and kicked it into your own face. $best was an easy win!';
    }
  }

  String _sophiaCommentary(MoveClassification c, String san, String best, String op, bool cap) {
    switch (c) {
      case MoveClassification.brilliant:
        return '💎 Wow, stunning! $san is a gorgeous sacrifice! You should be so proud of finding that!';
      case MoveClassification.great:
        return '⚡ Fantastic vision! $san keeps you in full control of the game!';
      case MoveClassification.best:
        return '⭐ Perfect move! You found the exact recommendation from Stockfish!';
      case MoveClassification.excellent:
        return '👍 Wonderful play! $san keeps your pieces happy and active.';
      case MoveClassification.good:
        return '✔️ Solid move! You are building good habits. $best is a fun alternative too.';
      case MoveClassification.book:
        return '📖 Great knowledge! You played theoretical book moves in the $op.';
      case MoveClassification.inaccuracy:
        return '⁉️ A small slip with $san, but completely okay! Let\'s look at $best together.';
      case MoveClassification.mistake:
        return '❓ Don\'t be discouraged! $san made things a bit tricky, but $best can teach us a lot.';
      case MoveClassification.blunder:
        return '❌ Oops, a tough moment with $san! Every grandmaster blunders too. Let\'s tap Retry Mistake and nail it!';
      case MoveClassification.miss:
        return '⭕ You almost had them! You were so close to a huge win with $best. Keep your head up!';
    }
  }

  String _magnusCommentary(MoveClassification c, String san, String best, String op, bool cap) {
    switch (c) {
      case MoveClassification.brilliant:
        return '💎 Clean. $san forces the win with zero defensive resources for the opponent.';
      case MoveClassification.great:
        return '⚡ Strong move. You recognized the critical moment and converted with $san.';
      case MoveClassification.best:
        return '⭐ The only move. Playing anything other than $san would be substandard.';
      case MoveClassification.excellent:
        return '👍 Acceptable. $san retains an edge, though I would have squeezed more out of it.';
      case MoveClassification.good:
        return '✔️ Decent, but $best creates much more practical discomfort for Black.';
      case MoveClassification.book:
        return '📖 Basic opening preparation in the $op.';
      case MoveClassification.inaccuracy:
        return '⁉️ Inaccurate. $san lets the opponent off the hook. $best suffocates them.';
      case MoveClassification.mistake:
        return '❓ Unacceptable mistake. In top-level chess, $san loses you the match immediately. Play $best.';
      case MoveClassification.blunder:
        return '❌ Resign-worthy blunder. $san is completely losing. $best was required.';
      case MoveClassification.miss:
        return '⭕ Completely inexcusable to miss $best. You let a winning position slip away.';
    }
  }
}
