# ♟️ Chess Analysis & Stockfish Mobile App (Flutter)

A modern, high-performance Flutter mobile application for chess analysis and game play featuring **Real Stockfish Engine integration** and **Chess.com style Game Review & Analysis**.

---

## 🌟 Key Features

### 1. 🤖 Real Stockfish Engine Integration
- **Full UCI Protocol**: Direct Universal Chess Interface communication using `stockfish_chess_engine` via native Dart FFI isolates.
- **Centipawn & Mate Depth**: Real evaluation in centipawns (e.g. `+1.8`, `-0.4`) and forced mate depth (`M2`, `-M4`).
- **Principal Variation (PV)**: Calculates multi-move best lines and alternatives.
- **Adjustable Depth & Skill**: Configurable calculation depths (Depth 8 - 20) and Stockfish Skill Levels (0 - 20).
- **Multi-tiered Engine Fallback**: Automatically cascades to native Stockfish, cloud Grandmaster evaluation, or built-in local minimax alpha-beta engine to ensure zero crashes on any device.

---

### 2. 📊 Chess.com Style Game Review (CAPS System)
- **Official Win-Probability CAPS Formula**: Calculates move-by-move win rate swings:
  $$W = \frac{100}{1 + 10^{-\text{centipawns} / 400}}$$
- **Move Accuracy %**: Generates weighted CAPS accuracy for White and Black (e.g. White 98.4% vs Black 71.2%).
- **Estimated Performance Elo**: Translates CAPS accuracy into estimated player ratings.
- **Move Classification System & Badges**:
  - 💎 **Brilliant (`!!`)**: Tactical piece sacrifice that preserves decisive advantage.
  - ⚡ **Great (`!`)**: Critical find that punishes an opponent error or the only winning move.
  - ⭐ **Best (`★`)**: Stockfish top recommendation.
  - 👍 **Excellent (`✓`)**: Near-perfect move with minimal advantage loss.
  - ✔️ **Good (`•`)**: Solid continuation.
  - 📖 **Book (`📖`)**: Opening book theory (automatic ECO opening database).
  - ⁉️ **Inaccuracy (`?!`)**: Minor mistake allowing counterplay.
  - ❓ **Mistake (`?`)**: Tangible tactical error dropping advantage.
  - ❌ **Blunder (`??`)**: Severe mistake or blunder of checkmate/material.
  - ⭕ **Missed Win (`✗`)**: Missed forced win or tactical opportunity.

---

### 3. 👨‍🏫 6 Selectable Virtual Review Coaches & Interactive "Retry Mistake"
- **Choose Your Review Coach**: Tap the coach badge or avatar at any time to switch coach personalities:
  1. **Coach Danny (`👨‍🏫`)**: Head Coach • Balanced, educational, and clear strategic advice.
  2. **Coach Gotham (`⚡`)**: High Energy • "AND HE SACRIFICES... THE PIECE!!", danger levels, and hype.
  3. **GM Vishy (`🧘‍♂️`)**: Grandmaster • Deep positional mastery, calm endgame and structure insights.
  4. **Coach Sarcasm (`🌶️`)**: The Roaster • Hilariously brutal, roasts blunders, questions moves.
  5. **Coach Sophia (`🌟`)**: Friendly Mentor • Positive, uplifting, encouraging bounce-backs.
  6. **Champion Magnus (`👑`)**: World Champion • Ruthless, demanding, uncompromising precision.
- **Coach Commentary**: Explains *why* a move was a blunder, what was threatened, and what the best continuation was.
- **Interactive Puzzle Mode**: When landing on any mistake, blunder, or missed win, tap **"Retry Mistake"** to reset the board to the critical moment and solve it live!
- **Tactical Arrows**:
  - Glowing Emerald Green Arrow: Stockfish top engine recommendation.
  - Dynamic Color Arrow: Played move (Red for blunder, Orange for mistake, Cyan for brilliant).

---

### 4. 📈 Advantage Graph & Eval Bar
- **Animated Eval Bar**: Vertical evaluation bar alongside the chessboard showing real-time win probability fill and centipawn / mate numerical labels.
- **Advantage Timeline Graph**: Powered by `fl_chart`, displaying momentum swings across all moves with clickable dots on critical moments (blunders, brilliant moves, mistakes). Scrub anywhere on the graph to jump to that move.

---

### 5. 🤖 Play Against Stockfish Bot Personalities
- **Jimmy (600 Elo)**: Beginner • Frequent blunders & relaxed play.
- **Noah (1000 Elo)**: Intermediate • Aggressive gambits and pawn pushes.
- **Nelson (1300 Elo)**: Club Player • Early Queen attacks and mate threats.
- **Elena (1750 Elo)**: Expert • Solid positional play and outposts.
- **Master Li (2200 Elo)**: Master • Deep calculation and tactical conversions.
- **Stockfish Max (3200 Elo)**: Superhuman • Stockfish Level 20.
- **One-Click Post-Game Review**: Analyze completed matches with Stockfish immediately upon game over.

---

### 6. 📥 PGN Import & Featured Masterpieces
- Paste any PGN or custom move list.
- Instant preloaded historical masterpieces:
  - *Paul Morphy's Opera Game (1858)*
  - *Garry Kasparov's Immortal (1999)*
  - *Bobby Fischer's Game of the Century (1956)*

---

## 📁 Project Architecture

```
lib/
├── main.dart                          # App entry point, dark theme, system UI
├── models/
│   ├── chess_move_eval.dart           # MoveEvaluation & MoveClassification enum
│   ├── game_review_data.dart          # GameReviewData (CAPS scores, breakdown maps)
│   └── bot_profile.dart               # Stockfish bot personalities & Elo ratings
├── services/
│   ├── stockfish_engine_service.dart  # Native Stockfish UCI & fallback engine manager
│   ├── analysis_engine.dart           # Full Game Reviewer & CAPS accuracy calculator
│   ├── opening_book_service.dart      # ECO opening book recognition (100+ openings)
│   ├── sample_review_service.dart     # Pre-analyzed Opera Game review
│   └── sound_service.dart             # Sound effects & haptic feedback
└── ui/
    ├── theme/
    │   └── chess_theme.dart           # Chess.com colors, styling, board square themes
    ├── widgets/
    │   ├── chess_board_widget.dart    # Interactive chessboard (tap, drag-drop, highlights)
    │   ├── chess_piece_widget.dart    # High-contrast vector piece renderer
    │   ├── board_arrows_painter.dart  # CustomPainter for Stockfish arrows
    │   ├── eval_bar_widget.dart       # Vertical animated evaluation bar
    │   ├── move_badge_widget.dart     # Chess.com badges (!!, ?, ??, etc.)
    │   ├── coach_card_widget.dart     # Coach avatar & interactive retry button
    │   ├── advantage_graph_widget.dart# FLChart evaluation curve & timeline
    │   └── move_history_list.dart     # Move history scroller & playback controls
    └── screens/
        ├── main_navigation_screen.dart# Bottom navigation (Review, Analysis, Bots, Import)
        ├── game_review_screen.dart    # Primary Chess.com Game Review screen
        ├── live_analysis_screen.dart  # Free Stockfish analysis board with depth & lines
        ├── play_bot_screen.dart       # Play vs Stockfish bot personalities
        └── pgn_import_screen.dart     # PGN paste & historical masterpieces
```

---

## 🚀 How to Run

### Run on Android / iOS (Mobile)
```bash
# Connect your mobile device or start emulator
flutter run
```

### Run on Windows Desktop
```bash
flutter run -d windows
```

### Run Automated Tests
```bash
flutter test
```
