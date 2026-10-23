import 'package:flutter/material.dart';

class BotProfile {
  final String id;
  final String name;
  final String subtitle;
  final int elo;
  final int skillLevel; // Stockfish Skill Level (0-20)
  final int searchDepth; // Stockfish search depth
  final double blunderChance; // Chance to make random sub-optimal move
  final String avatarEmoji;
  final Color themeColor;
  final String description;
  final String playStyle;

  const BotProfile({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.elo,
    required this.skillLevel,
    required this.searchDepth,
    required this.blunderChance,
    required this.avatarEmoji,
    required this.themeColor,
    required this.description,
    required this.playStyle,
  });

  static const List<BotProfile> presets = [
    BotProfile(
      id: 'jimmy',
      name: 'Jimmy',
      subtitle: 'Beginner • Learning Chess',
      elo: 600,
      skillLevel: 1,
      searchDepth: 2,
      blunderChance: 0.35,
      avatarEmoji: '🐣',
      themeColor: Color(0xFF4CAF50),
      description: 'Jimmy is new to chess! He often leaves pieces undefended and forgets about checks.',
      playStyle: 'Casual & Relaxed',
    ),
    BotProfile(
      id: 'noah',
      name: 'Noah',
      subtitle: 'Intermediate • Active Gambits',
      elo: 1000,
      skillLevel: 4,
      searchDepth: 4,
      blunderChance: 0.20,
      avatarEmoji: '🦊',
      themeColor: Color(0xFF29B6F6),
      description: 'Noah loves early attacks and simple tactics. Watch out for his pawn pushes!',
      playStyle: 'Tactical Attacker',
    ),
    BotProfile(
      id: 'nelson',
      name: 'Nelson',
      subtitle: 'Club Player • Queen Menace',
      elo: 1300,
      skillLevel: 8,
      searchDepth: 7,
      blunderChance: 0.10,
      avatarEmoji: '🦁',
      themeColor: Color(0xFFFF9800),
      description: 'Nelson brings his queen out early and loves looking for sneaky checkmates.',
      playStyle: 'Aggressive Aggro',
    ),
    BotProfile(
      id: 'elena',
      name: 'Elena',
      subtitle: 'Expert • Solid Positional',
      elo: 1750,
      skillLevel: 13,
      searchDepth: 10,
      blunderChance: 0.04,
      avatarEmoji: '🦉',
      themeColor: Color(0xFFAB47BC),
      description: 'Elena plays strong positional chess, controls central outposts and punishes small errors.',
      playStyle: 'Positional Master',
    ),
    BotProfile(
      id: 'master_li',
      name: 'Master Li',
      subtitle: 'Master • Ruthless Tactician',
      elo: 2200,
      skillLevel: 17,
      searchDepth: 14,
      blunderChance: 0.01,
      avatarEmoji: '🐉',
      themeColor: Color(0xFFEF5350),
      description: 'A seasoned chess master who will exploit every inaccuracy and calculate deep combinations.',
      playStyle: 'Master Level',
    ),
    BotProfile(
      id: 'stockfish_max',
      name: 'Stockfish Max',
      subtitle: 'Grandmaster Engine • Level 20',
      elo: 3200,
      skillLevel: 20,
      searchDepth: 18,
      blunderChance: 0.0,
      avatarEmoji: '⚡',
      themeColor: Color(0xFF00E676),
      description: 'The full power of the world champion chess engine Stockfish. Utterly unstoppable.',
      playStyle: 'Superhuman Perfect',
    ),
  ];
}
